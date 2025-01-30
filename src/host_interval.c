#define _GNU_SOURCE
#include <sys/syscall.h>
#include <linux/perf_event.h>
#include <err.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/resource.h>
#include <sched.h>

static long perf_event_open(struct perf_event_attr *hw_event, pid_t pid,
                            int cpu, int group_fd, unsigned long flags) {
    return syscall(SYS_perf_event_open, hw_event, pid, cpu, group_fd, flags);
}

static uint64_t read_counter(int fd) {
  uint64_t count;
  if (read(fd, &count, sizeof count) < 0)
    err(EXIT_FAILURE, "read");
  return count;
}

static void usage(FILE *f, const char *prog) {
  fprintf(f, "usage: %s begin end [--] program [arg...]\n",
          prog);
}

static uint64_t parse_u64(const char *s) {
  char *end;
  const uintmax_t result = strtoumax(s, &end, 0);
  if (*s == '\0' || *end != '\0')
    err(EXIT_FAILURE, "bad u64: %s", s);
  if (result > UINT64_MAX)
    err(EXIT_FAILURE, "doesn't fit in u64: %s", s);
  return (uint64_t) result;
}

static void setcpu(int cpu) {
  cpu_set_t mask;
  CPU_ZERO(&mask);
  CPU_SET(cpu, &mask);
  if (sched_setaffinity(0, sizeof mask, &mask) < 0)
    err(EXIT_FAILURE, "sched_setaffinity");
}

int main(int argc, char *argv[]) {
  int optc;
  while ((optc = getopt(argc, argv, "h")) >= 0) {
    switch (optc) {
    case 'h':
      usage(stdout, argv[0]);
      return EXIT_SUCCESS;
    default:
      usage(stderr, argv[0]);
      return EXIT_FAILURE;
    }
  }

  if (argc - optind < 3) {
    usage(stderr, argv[0]);
    return EXIT_FAILURE;
  }

  const uint64_t begin = parse_u64(argv[optind++]);
  const uint64_t end = parse_u64(argv[optind++]);
  char **cmd = &argv[optind];

  // Run the parent on CPU 0.
  setcpu(0);

  // Fork+exec the child, requesting tracing.
  const pid_t pid = fork();
  if (pid < 0) {
    err(EXIT_FAILURE, "fork");
  } else if (pid == 0) {
    setcpu(2);
    if (ptrace(PTRACE_TRACEME, 0, 0, 0) < 0)
      err(EXIT_FAILURE, "ptrace: PTRACE_TRACEME");
    execvp(cmd[0], cmd);
    err(EXIT_FAILURE, "execvp: %s", cmd[0]);
  }

  // Wait for the child process.
  int status;
  if (wait(&status) < 0)
    err(EXIT_FAILURE, "wait: initial wait");
  if (!(WIFSTOPPED(status) && WSTOPSIG(status) == SIGTRAP))
    errx(EXIT_FAILURE, "wait: child not stopped with SIGTRAP");

  // Set up the performance counter for the child.
  struct perf_event_attr pea;
  memset(&pea, 0, sizeof pea);
  pea.type = PERF_TYPE_HARDWARE;
  pea.size = sizeof pea;
  pea.config = PERF_COUNT_HW_INSTRUCTIONS;
  pea.sample_period = begin; // break at the beginning of the interval
  pea.disabled = 1;
  pea.exclude_kernel = 1;
  pea.exclude_hv = 1;
  pea.pinned = 1;
  pea.precise_ip = 2;
  pea.wakeup_events = 1; // wake up immediately when instruction count is reached.
  int inst_fd;
  if ((inst_fd = perf_event_open(&pea, pid, -1, -1, 0)) < 0)
    err(EXIT_FAILURE, "perf_event_open: instructions");

  // Set up signals.
  if (fcntl(inst_fd, F_SETFL, O_ASYNC) < 0 ||
      fcntl(inst_fd, F_SETSIG, SIGIO) < 0 ||
      fcntl(inst_fd, F_SETOWN, pid) < 0)
    err(EXIT_FAILURE, "fcntl");

  // Enable performance counter.
  if (ioctl(inst_fd, PERF_EVENT_IOC_RESET, 0) < 0 ||
      ioctl(inst_fd, PERF_EVENT_IOC_ENABLE, 0) < 0)
    err(EXIT_FAILURE, "ioctl");


  // Now, set up counter for counting hardware time.
  memset(&pea, 0, sizeof pea);
  pea.type = PERF_TYPE_HARDWARE;
  pea.size = sizeof pea;
  pea.config = PERF_COUNT_HW_REF_CPU_CYCLES;
  pea.disabled = 1;
  pea.exclude_kernel = 1;
  pea.exclude_hv = 1;
  pea.pinned = 1;
  int time_fd;
  if ((time_fd = perf_event_open(&pea, pid, -1, -1, inst_fd)) < 0)
    err(EXIT_FAILURE, "perf_event_open: time");
  if (ioctl(time_fd, PERF_EVENT_IOC_RESET, 0) < 0 ||
      ioctl(time_fd, PERF_EVENT_IOC_ENABLE, 0) < 0)
    err(EXIT_FAILURE, "ioctl");
  
  
  // Run the child.
  if (ptrace(PTRACE_CONT, pid, 0, 0) < 0)
    err(EXIT_FAILURE, "ptrace: PTRACE_CONT");

  // Expect to receive a SIGIO stop.
  if (wait(&status) < 0)
    err(EXIT_FAILURE, "wait");
  if (!(WIFSTOPPED(status) && WSTOPSIG(status) == SIGIO))
    errx(EXIT_FAILURE, "received wait status other than SIGIO stop");

  // Read the counter for funsies.
  const uint64_t i_begin = read_counter(inst_fd);
  const uint64_t t_begin = read_counter(time_fd);

  // Now, run until the end of the interval.
  const uint64_t new_period = end - begin;
  if (ioctl(inst_fd, PERF_EVENT_IOC_PERIOD, &new_period) < 0)
    err(EXIT_FAILURE, "ioctl: PERF_EVENT_IOC_PERIOD");

  if (ptrace(PTRACE_CONT, pid, 0, 0) < 0)
    err(EXIT_FAILURE, "ptrace: PTRACE_CONT");

  // Except to receive a SIGIO stop, again.
  if (wait(&status) < 0)
    err(EXIT_FAILURE, "wait");
  if (!(WIFSTOPPED(status) && WSTOPSIG(status) == SIGIO))
    errx(EXIT_FAILURE, "received wait status other than SIGIO stop");

  // Read the counter for funsies.
  const uint64_t i_end = read_counter(inst_fd);
  const uint64_t t_end = read_counter(time_fd);

  // Terminate the child.
  if (ptrace(PTRACE_CONT, pid, 0, SIGTERM) < 0)
    err(EXIT_FAILURE, "ptrace");
  if (wait(NULL) < 0)
    err(EXIT_FAILURE, "wait");
  
  // Print out the results.
  printf("instructions: %ld %ld %ld\n"
         "ref_cycles: %ld %ld %ld\n",
         i_begin, i_end, i_end - i_begin,
         t_begin, t_end, t_end - t_begin);
}

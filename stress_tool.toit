import .config as config
import math

class StressTester:
  static MIN  ::= 0.20
  static MEDIUM  ::= 0.65
  static HIGH ::= 0.90
  static MAX  ::= 1.00

  tasks_count/int
  intensity/float
  duration/Duration?
  should_print/bool

  constructor --.tasks_count=5 --.intensity=MEDIUM --.duration=null --.should_print=false:

  run:
    if should_print:
      print "--- STRESS TOOL INITIALIZED ---"
      print "Tasks: $tasks_count"
      print "Intensity: $(intensity * 100)%"
      print "Duration: $(duration ? duration : "Infinite")"
    
    start_time := Time.monotonic_us

    tasks_count.repeat: | id |
      task:: _worker_loop id
    
    // Only start the monitor if printing is enabled
    if should_print:
      task:: _monitor_loop start_time

    if duration:
      sleep duration
      if should_print:
        print "--- STRESS TEST COMPLETE ---"
        end_time := Time.monotonic_us
        print "Total time elapsed: $((end_time - start_time) / 1_000_000)s"
      exit 0
    else:
      while true: sleep (Duration --h=24)

  _monitor_loop start_time/int:
    while true:
      sleep (Duration --s=5)
      now := Time.monotonic_us
      elapsed_us := now - start_time
      elapsed_s := elapsed_us / 1_000_000
      
      if duration:
        percent := (elapsed_us * 100 / duration.in_us).to_int
        if percent < 100:
          print ">>> [Monitor] Progress: $percent% ($(elapsed_s)s / $(duration.in_s)s)"
      else:
        print ">>> [Monitor] Running: $(elapsed_s)s (Infinite mode)"

  _worker_loop id/int:
    if should_print:
      print "[Task $id] Online"
    while true:
      work_start := Time.monotonic_us
      _run_heavy_load
      _run_pi_load
      work_duration := Time.monotonic_us - work_start
      
      if intensity < 1.0:
        sleep_us := (work_duration * (1.0 / intensity - 1.0)).to_int
        sleep (Duration --us=sleep_us)
      else:
        yield

  _run_heavy_load:
    // Mandelbrot set calculation - computationally intensive floating point math
    width := 50
    height := 50
    max_iter := 500
    
    height.repeat: | y |
      yield
      width.repeat: | x |
        zx := 0.0
        zy := 0.0
        // Map pixel to complex plane
        cx := (x - width / 1.5) * 3.0 / width
        cy := (y - height / 2.0) * 3.0 / height
        
        iter := max_iter
        while zx * zx + zy * zy < 4.0 and iter > 0:
          tmp := zx * zx - zy * zy + cx
          zy = 2.0 * zx * zy + cy
          zx = tmp
          iter--

  _run_pi_load:
    // Monte Carlo Pi estimation - intensive random number generation and math
    iterations := 20_000
    inside := 0
    iterations.repeat: | i |
      if i % 1000 == 0: yield
      x := (random 1000) / 1000.0
      y := (random 1000) / 1000.0
      if x * x + y * y <= 1.0:
        inside++


main args/List:
  tasks := config.DEFAULT_TASKS
  duration_s := config.DURATION
  print_enabled := args.contains "--print"

  tester := StressTester
    --tasks_count=tasks
    --intensity=config.DEFAULT_INTENSITY
    --duration=(duration_s != 0 ? (Duration --s=duration_s) : null)
    --should_print=print_enabled
  
  tester.run

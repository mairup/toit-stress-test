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
  mandelbrot_iterations/int
  pi_iterations/int

  constructor --.tasks_count=5 --.intensity=MEDIUM --.duration=null --.mandelbrot_iterations=500 --.pi_iterations=20000:

  run:
    print "--- STRESS TOOL INITIALIZED ---"
    print "Tasks: $tasks_count"
    print "Intensity: $(intensity * 100)%"
    print "Mandelbrot iterations: $mandelbrot_iterations"
    print "Pi iterations: $pi_iterations"
    print "Duration: $(duration ? duration : "Infinite")"
    
    start_time := Time.monotonic_us

    tasks_count.repeat: | id |
      task:: _worker_loop id

    if duration:
      sleep duration
      print "--- STRESS TEST COMPLETE ---"
      end_time := Time.monotonic_us
      print "Total time elapsed: $((end_time - start_time) / 1_000_000)s"
      exit 0
    else:
      while true: sleep (Duration --h=24)

  _worker_loop id/int:
    print "[Task $id] Online"
    i := 0
    while true:
      work_start := Time.monotonic_us
      _run_heavy_load
      _run_pi_load
      work_duration := Time.monotonic_us - work_start
      
      if intensity < 1.0:
        sleep_us := (work_duration * (1.0 / intensity - 1.0)).to_int
        sleep (Duration --us=sleep_us)
      
      i++
      if i % 10 == 0:
        print "[Task $id] Completed $i cycles"

  _run_heavy_load:
    // Mandelbrot set calculation - computationally intensive floating point math
    width := 50
    height := 50
    
    height.repeat: | y |
      width.repeat: | x |
        zx := 0.0
        zy := 0.0
        // Map pixel to complex plane
        cx := (x - width / 1.5) * 3.0 / width
        cy := (y - height / 2.0) * 3.0 / height
        
        iter := mandelbrot_iterations
        while zx * zx + zy * zy < 4.0 and iter > 0:
          tmp := zx * zx - zy * zy + cx
          zy = 2.0 * zx * zy + cy
          zx = tmp
          iter--

  _run_pi_load:
    // Monte Carlo Pi estimation - intensive random number generation and math
    iterations := pi_iterations
    inside := 0
    iterations.repeat:
      x := (random 1000) / 1000.0
      y := (random 1000) / 1000.0
      if x * x + y * y <= 1.0:
        inside++


main args/List:
  tasks := config.DEFAULT_TASKS
  if args.size > 0:
    tasks = int.parse args[0]

  mandel_iters := 500
  if config.MANDELBROT_ITERATIONS:
    mandel_iters = config.MANDELBROT_ITERATIONS
  
  pi_iters := 20000
  if config.PI_ITERATIONS:
    pi_iters = config.PI_ITERATIONS

  duration_s /int? := config.DEFAULT_DURATION_SECONDS
  tester := StressTester
    --tasks_count=tasks
    --intensity=config.DEFAULT_INTENSITY
    --duration=(duration_s ? (Duration --s=duration_s) : null)
    --mandelbrot_iterations=mandel_iters
    --pi_iterations=pi_iters
  
  tester.run

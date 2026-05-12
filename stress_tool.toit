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

  constructor --.tasks_count=5 --.intensity=MEDIUM --.duration=null:

  run:
    print "--- STRESS TOOL INITIALIZED ---"
    print "Tasks: $tasks_count"
    print "Intensity: $(intensity * 100)%"
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
      _run_matrix_load
      work_duration := Time.monotonic_us - work_start
      
      if intensity < 1.0:
        sleep_us := (work_duration * (1.0 / intensity - 1.0)).to_int
        sleep (Duration --us=sleep_us)
      
      i++
      if i % 10 == 0:
        print "[Task $id] Completed $i cycles"

  _run_heavy_load:
    iterations := (random 500_000) + 100_000
    sum := 0
    iterations.repeat: | i |
      sum += i
      if i % 100 == 0: sum -= random i

  _run_matrix_load:
    exponent := (random 4) + 4
    dim := (math.pow 2 exponent).to_int
    a := Matrix dim dim (List dim: List dim: random 100)
    b := Matrix dim dim (List dim: List dim: random 100)
    a.multiply b

class Matrix:
  rows/int
  cols/int
  data/List

  constructor .rows .cols .data:

  multiply other/Matrix -> Matrix:
    if cols != other.rows: throw "Incompatible dimensions"
    result := List rows: List other.cols: 0
    rows.repeat: | i |
      other.cols.repeat: | j |
        cols.repeat: | k |
          result[i][j] += data[i][k] * other.data[k][j]
    return Matrix rows other.cols result

/** 
Transforms a list of CLI tokens into a parameter map.
Handles mapping of short flags (-i, -t, -d) to full names.
*/
extract_args args/List -> Map:
  params := {:}
  args.do: | arg |
    key := ""
    value := ""
    if arg.starts_with "--":
      parts := arg.split "="
      key = parts[0][2..]
      if parts.size > 1: value = parts[1]
    else if arg.starts_with "-":
      parts := arg.split "="
      short := parts[0][1..]
      if parts.size > 1: value = parts[1]
      
      if short == "i": key = "intensity"
      else if short == "t": key = "taskn"
      else if short == "d": key = "duration"
    
    if key != "": params[key] = value
  return params

/** Interfaces for creating and configuring StressTester from a parameter map. */
run_from_config params/Map:
  tasks := config.DEFAULT_TASKS
  if params.contains "taskn": tasks = int.parse params["taskn"]

  intensity := config.DEFAULT_INTENSITY
  if params.contains "intensity":
    raw := params["intensity"]
    if raw == "min": intensity = StressTester.MIN
    else if raw == "medium": intensity = StressTester.MEDIUM
    else if raw == "high": intensity = StressTester.HIGH
    else if raw == "max": intensity = StressTester.MAX
    else: intensity = float.parse raw

  duration_s /int? := config.DEFAULT_DURATION_SECONDS
  if params.contains "duration":
    raw := params["duration"]
    duration_s = (raw == "infinite" ? null : int.parse raw)

  tester := StressTester
    --tasks_count=tasks
    --intensity=intensity
    --duration=(duration_s ? (Duration --s=duration_s) : null)
  
  tester.run

main args/List:
  if args.contains "--help" or args.contains "-h" or args.size == 0:
    print "Usage: toit run stress_tool.toit [options]"
    print "Options:"
    print "  -t, --taskn=N      Number of concurrent tasks (default: $config.DEFAULT_TASKS)"
    print "  -i, --intensity=V  Load level (min, medium, high, max, or 0.0-1.0)"
    print "  -d, --duration=N   Run duration in seconds or 'infinite'"
    exit 0

  params := extract_args args
  run_from_config params


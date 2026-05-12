import host.file
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

parse_cfg config_string/string -> Map:
  params := {:}
  lines := config_string.split "\n"
  lines.do: | line |
    line = line.trim
    if line != "" and not (line.starts_with "#") and line.contains "=":
      parts := line.split "="
      params[parts[0].trim] = parts[1].trim
  return params

main:
  // Read from the Linux filesystem
  config_string := (file.read_contents "parameters.cfg").to_string
  cfg := parse_cfg config_string

  tasks := cfg.contains "DEFAULT_TASKS" ? int.parse cfg["DEFAULT_TASKS"] : 5
  intensity := cfg.contains "DEFAULT_INTENSITY" ? float.parse cfg["DEFAULT_INTENSITY"] : 0.65
  
  duration_s /int? := 30
  if cfg.contains "DEFAULT_DURATION_SECONDS":
    raw := cfg["DEFAULT_DURATION_SECONDS"]
    duration_s = (raw == "null" or raw == "infinite") ? null : int.parse raw

  tester := StressTester
    --tasks_count=tasks
    --intensity=intensity
    --duration=(duration_s ? (Duration --s=duration_s) : null)
  
  tester.run

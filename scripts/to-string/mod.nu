use internal.nu *

export def "to string" [
  --record(-r)
  --table(-t)
  --indent(-i) :int
] : [ any -> string ] {
  if $record {
    $in | record-to-string --indent=$indent
  } else if $table {
    $in | table-to-string --indent=$indent
  } else {
    print $"(ansi red)Error: Please specify --record or --table(ansi reset)"
  }
}

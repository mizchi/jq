///|
async fn main {
  let cmd = @argparse.Command::new(
    "moonjq",
    about="A jq clone in MoonBit",
    version="0.1.0",
    positionals=[
      @argparse.PositionArg::new("filter", about="jq filter expression"),
    ],
  )
  let matches = cmd.parse() catch {
    _ => {
      println(cmd.render_help())
      return
    }
  }
  let filter_str = match matches.values.get("filter") {
    Some(vals) =>
      match vals {
        [f, ..] => f
        _ => {
          println(cmd.render_help())
          return
        }
      }
    None => {
      println(cmd.render_help())
      return
    }
  }
  // Read stdin
  let data = @stdio.stdin.read_all()
  let input_str = data.text()
  // Parse JSON
  let input = @json.parse(input_str) catch {
    _ => {
      println("Error: invalid JSON input")
      return
    }
  }
  // Run filter
  let results = @jq.run(filter_str, input) catch {
    @jq.JqError::JqError(msg) => {
      println("Error: " + msg)
      return
    }
  }
  // Output
  for r in results {
    println(r.stringify())
  }
}

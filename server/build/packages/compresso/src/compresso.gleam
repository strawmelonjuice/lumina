import compresso/compression
import gleam/bit_array
import gleam/option.{None, Some}
import gleam/yielder

/// Compresses the given data using gzip.
pub fn gzip(data: BitArray) -> BitArray {
  compression.gzip(data)
}

type YielderAcc {
  YielderAcc(
    stream: compression.Stream,
    uncompressed: yielder.Yielder(BitArray),
    done: Bool,
  )
}

/// Lazily compresses data using gzip.
pub fn gzip_yielder(
  uncompressed: yielder.Yielder(BitArray),
) -> yielder.Yielder(BitArray) {
  let stream = compression.init_stream()

  let assert Ok(Nil) =
    compression.init_deflate(
      stream,
      compression_level: Some(compression.default_compression),
      window_bits: Some(15 + 16),
      memory_level: None,
      strategy: None,
    )

  let acc = YielderAcc(stream:, uncompressed:, done: False)

  yielder.unfold(acc, fn(acc) {
    case acc.done {
      True -> yielder.Done
      False -> {
        let #(compressed, acc) = deflate_until_not_empty(acc)
        yielder.Next(element: compressed, accumulator: acc)
      }
    }
  })
}

fn deflate_until_not_empty(acc: YielderAcc) -> #(BitArray, YielderAcc) {
  case yielder.step(acc.uncompressed) {
    yielder.Done -> {
      let last_chunk =
        compression.deflate(acc.stream, <<>>, compression.Finish)
        |> bit_array.concat()

      let assert Ok(Nil) = compression.end_deflate(acc.stream)
      compression.close_stream(acc.stream)

      #(last_chunk, YielderAcc(..acc, done: True))
    }
    yielder.Next(data, rest) -> {
      let compressed = compression.deflate(acc.stream, data, compression.None)

      case compressed {
        [] -> deflate_until_not_empty(YielderAcc(..acc, uncompressed: rest))
        compressed -> {
          #(bit_array.concat(compressed), YielderAcc(..acc, uncompressed: rest))
        }
      }
    }
  }
}

/// Decompresses the given data using gzip.
pub fn gunzip(data: BitArray) -> BitArray {
  compression.gunzip(data)
}

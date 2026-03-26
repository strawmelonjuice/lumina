import exception
import gleam/erlang/atom
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string
import logging

pub type Stream

pub fn init_stream() -> Stream {
  open()
}

pub fn close_stream(stream: Stream) -> Nil {
  close(stream)
}

pub const default_compression = 6

pub const no_compression = 0

pub const best_speed_compression = 1

pub const best_compression = 9

pub type CompressionStrategy {
  Default
  Filtered
  HuffmanOnly
  RLE
}

pub fn init_deflate(
  stream: Stream,
  compression_level compression_level: Option(Int),
  window_bits window_bits: Option(Int),
  memory_level memory_level: Option(Int),
  strategy strategy: Option(CompressionStrategy),
) -> Result(Nil, Nil) {
  let compression_level = case compression_level {
    Some(level) if level >= 0 && level <= 9 -> level
    _ -> default_compression
  }

  let window_bits = option.unwrap(window_bits, 15)

  let memory_level = case memory_level {
    Some(level) if level >= 1 && level <= 9 -> level
    _ -> 8
  }

  let strategy = case strategy {
    Some(strategy) ->
      atom.create(case strategy {
        Default -> "default"
        Filtered -> "filtered"
        HuffmanOnly -> "huffman_only"
        RLE -> "rle"
      })
    _ -> atom.create("default")
  }

  exception.rescue(fn() {
    deflate_init(
      stream,
      compression_level,
      Deflated,
      window_bits,
      memory_level,
      strategy,
    )
  })
  |> result.replace(Nil)
  |> result.map_error(fn(e) {
    logging.log(
      logging.Error,
      "Failed to initialize deflate: " <> string.inspect(e),
    )

    Nil
  })
}

@external(erlang, "zlib", "open")
fn open() -> Stream

@external(erlang, "zlib", "close")
fn close(stream: Stream) -> Nil

type CompressionMethod {
  Deflated
}

@external(erlang, "zlib", "deflateInit")
fn deflate_init(
  stream: Stream,
  compression_level: Int,
  method: CompressionMethod,
  window_bits: Int,
  mem_level: Int,
  strategy: atom.Atom,
) -> atom.Atom

pub type Flush {
  None
  Sync
  Full
  Finish
}

@external(erlang, "zlib", "deflate")
pub fn deflate(stream: Stream, data: BitArray, flush: Flush) -> List(BitArray)

pub fn end_deflate(stream: Stream) -> Result(Nil, Nil) {
  exception.rescue(fn() { deflate_end(stream) })
  |> result.replace(Nil)
  |> result.map_error(fn(e) {
    logging.log(logging.Error, "Failed to end deflate: " <> string.inspect(e))
    Nil
  })
}

@external(erlang, "zlib", "deflateEnd")
fn deflate_end(stream: Stream) -> atom.Atom

@external(erlang, "zlib", "gzip")
pub fn gzip(data: BitArray) -> BitArray

@external(erlang, "zlib", "gunzip")
pub fn gunzip(data: BitArray) -> BitArray

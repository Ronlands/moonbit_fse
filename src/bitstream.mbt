///| 位流操作模块
///| 提供位级别的读写操作，用于FSE和Huffman编码

///| 位流写入器（编码时使用）
pub struct BitCStream {
  mut bit_container : UInt64  // 位容器
  mut bit_pos : Int           // 当前位位置
  buffer : Array[Byte]        // 输出缓冲区
  mut ptr : Int               // 当前写入位置
}

///| 位流读取器（解码时使用）
pub struct BitDStream {
  mut bit_container : UInt64  // 位容器
  mut bits_consumed : Int     // 已消耗的位数
  buffer : Bytes              // 输入缓冲区
  mut ptr : Int               // 当前读取位置
  start : Int                 // 起始位置
}

///| 位流状态
pub enum BitDStreamStatus {
  Unfinished
  EndOfBuffer
  Completed
  Overflow
}

///| 创建位流写入器
pub fn BitCStream::new(capacity : Int) -> BitCStream {
  BitCStream::{
    bit_container: 0UL,
    bit_pos: 0,
    buffer: Array::new(capacity=capacity),
    ptr: 0
  }
}

///| 添加位到位流
pub fn add_bits(self : BitCStream, value : UInt64, nb_bits : Int) -> Unit {
  self.bit_container = self.bit_container | (value << self.bit_pos)
  self.bit_pos = self.bit_pos + nb_bits
}

///| 刷新位到缓冲区
pub fn flush_bits(self : BitCStream) -> Unit {
  let bytes_to_write = self.bit_pos / 8
  for i in 0..<bytes_to_write {
    let byte = ((self.bit_container >> (i * 8)) & 0xFFUL).to_byte()
    if self.ptr < self.buffer.length() {
      self.buffer[self.ptr] = byte
    } else {
      self.buffer.push(byte)
    }
    self.ptr = self.ptr + 1
  }
  self.bit_container = self.bit_container >> (bytes_to_write * 8)
  self.bit_pos = self.bit_pos - bytes_to_write * 8
}

///| 关闭位流并返回字节数组
pub fn close(self : BitCStream) -> Bytes {
  // 刷新剩余的位
  if self.bit_pos > 0 {
    let remaining_bytes = (self.bit_pos + 7) / 8
    for i in 0..<remaining_bytes {
      let byte = ((self.bit_container >> (i * 8)) & 0xFFUL).to_byte()
      if self.ptr < self.buffer.length() {
        self.buffer[self.ptr] = byte
      } else {
        self.buffer.push(byte)
      }
      self.ptr = self.ptr + 1
    }
  }
  Bytes::from_array(self.buffer)
}

///| 创建位流读取器
pub fn BitDStream::new(buffer : Bytes) -> BitDStream {
  let mut initial_container = 0UL
  let bytes_to_read = if buffer.length() >= 8 { 8 } else { buffer.length() }
  
  for i in 0..<bytes_to_read {
    initial_container = initial_container | (buffer[i].to_uint64() << (i * 8))
  }
  
  BitDStream::{
    bit_container: initial_container,
    bits_consumed: 0,
    buffer,
    ptr: bytes_to_read,
    start: 0
  }
}

///| 从位流读取位
pub fn read_bits(self : BitDStream, nb_bits : Int) -> UInt64 {
  let mask = (1UL << nb_bits) - 1UL
  let result = self.bit_container & mask
  self.bit_container = self.bit_container >> nb_bits
  self.bits_consumed = self.bits_consumed + nb_bits
  result
}

///| 重新加载位流
pub fn reload(self : BitDStream) -> BitDStreamStatus {
  if self.bits_consumed < 64 {
    return BitDStreamStatus::Unfinished
  }
  
  if self.ptr >= self.buffer.length() {
    return BitDStreamStatus::Completed
  }
  
  // 重新加载8字节
  let mut new_container = 0UL
  let bytes_to_read = if self.ptr + 8 <= self.buffer.length() { 
    8 
  } else { 
    self.buffer.length() - self.ptr 
  }
  
  for i in 0..<bytes_to_read {
    new_container = new_container | (self.buffer[self.ptr + i].to_uint64() << (i * 8))
  }
  
  self.bit_container = new_container
  self.ptr = self.ptr + bytes_to_read
  self.bits_consumed = 0
  
  if self.ptr >= self.buffer.length() {
    BitDStreamStatus::EndOfBuffer
  } else {
    BitDStreamStatus::Unfinished
  }
}

///| 检查是否到达流末尾
pub fn end_of_stream(self : BitDStream) -> Bool {
  self.ptr >= self.buffer.length() && self.bits_consumed >= 64
}

///| 计算前导零位数（用于归一化）
pub fn highbit32(val : UInt) -> Int {
  if val == 0 {
    return 0
  }
  let mut v = val
  let mut count = 0
  while v > 1 {
    v = v >> 1
    count = count + 1
  }
  count
}


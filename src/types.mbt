/// 类型定义模块
/// 定义FSE和Huffman压缩相关的数据结构

///|
/// 压缩结果枚举
pub enum CompressionResult {
  Success(Bytes) // 成功压缩
  NotCompressible // 数据不可压缩
  SingleSymbol(Bytes) // 单符号数据（RLE）
  Error(String) // 错误
} derive(Show)

///|
/// FSE压缩选项
pub struct FSEOptions {
  max_symbol_value : Int
  table_log : Int
  use_optimal_table_log : Bool
}

///|
/// Huffman压缩选项
pub struct HuffmanOptions {
  max_symbol_value : Int
  use_canonical_codes : Bool
}

///|
/// 简单的压缩结果
pub struct SimpleResult {
  data : Bytes
  ratio : Double
  algorithm : String
}

///|
/// 创建默认FSE选项
pub fn create_default_fse_options() -> FSEOptions {
  FSEOptions::{
    max_symbol_value: 255,
    table_log: 0, // 0表示使用默认值
    use_optimal_table_log: true,
  }
}

///|
/// 创建默认Huffman选项
pub fn create_default_huffman_options() -> HuffmanOptions {
  HuffmanOptions::{ max_symbol_value: 255, use_canonical_codes: true }
}

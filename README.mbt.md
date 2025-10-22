# MoonBit Finite State Entropy (FSE) 库

这是一个用MoonBit语言实现的有限状态熵编码库，包含FSE和Huffman编码算法。

## 功能特性

- **FSE (Finite State Entropy)**: 基于ANS理论的熵编码器，提供接近算术编码的压缩精度，但速度更快
- **Huffman编码**: 经典的哈夫曼编码算法，针对现代CPU优化
- **位流处理**: 高效的位级数据操作
- **智能压缩**: 自动选择最适合的压缩算法
- **纯MoonBit实现**: 无需外部依赖，完全用MoonBit编写

## 算法优势

### FSE算法
- 压缩比接近香农极限
- 比算术编码快得多
- 支持任意概率分布

### Huffman算法  
- 极快的压缩和解压缩速度
- 适合现代CPU的乱序执行
- 在均匀分布下表现优异

## 使用示例

```moonbit
// 自动选择最佳压缩方法
let data = "Hello, World!".to_bytes()
let result = auto_compress_simple(data)
println("压缩比: " + result.ratio.to_string())

// 使用指定方法压缩
let huffman_result = simple_huffman_compress(data)
let fse_result = simple_fse_compress(data)

// 智能解压缩
let decompressed = smart_decompress_simple(compressed_data)

// 数据特征分析
let analysis = analyze_data_simple(data)
println(analysis)
```

## 性能基准

还没测试

## 许可证

Apache-2.0 License
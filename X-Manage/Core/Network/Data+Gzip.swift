//
//  Data+Gzip.swift
//  X-Manage
//
//  Gzip 压缩扩展 - 使用系统 Compression 框架
//

import Foundation
import Compression

extension Data {

    /// gzip 压缩
    /// - Returns: 压缩后的数据，失败返回 nil
    func gzipCompressed() -> Data? {
        guard !isEmpty else { return nil }

        var sourceBuffer = [UInt8](self)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { destinationBuffer.deallocate() }

        let compressedSize = compression_encode_buffer(
            destinationBuffer, count,
            &sourceBuffer, count,
            nil,
            COMPRESSION_ZLIB
        )

        guard compressedSize > 0 else { return nil }

        // 添加 gzip 头和尾
        var gzipData = Data()
        // gzip 头 (10 bytes): magic number, compression method, flags, mtime, xfl, os
        gzipData.append(contentsOf: [0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        // 压缩数据
        gzipData.append(Data(bytes: destinationBuffer, count: compressedSize))
        // CRC32 (4 bytes)
        let crc = self.crc32()
        var crcValue = crc.littleEndian
        gzipData.append(contentsOf: Swift.withUnsafeBytes(of: &crcValue) { Array($0) })
        // 原始大小 (4 bytes)
        var sizeValue = UInt32(count).littleEndian
        gzipData.append(contentsOf: Swift.withUnsafeBytes(of: &sizeValue) { Array($0) })

        return gzipData
    }

    /// 计算 CRC32 校验和
    private func crc32() -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in self {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ (crc & 1 != 0 ? 0xEDB88320 : 0)
            }
        }
        return ~crc
    }
}

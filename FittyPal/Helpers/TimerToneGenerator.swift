import Foundation

enum TimerToneGenerator {
    static func makeToneData(frequency: Double, duration: TimeInterval, sampleRate: Double = 44100) -> Data {
        guard frequency > 0, duration > 0 else { return Data() }
        let sampleCount = Int(sampleRate * duration)
        guard sampleCount > 0 else { return Data() }

        var sampleData = Data(capacity: sampleCount * MemoryLayout<Int16>.size)
        for index in 0..<sampleCount {
            let sample = sin(2 * .pi * frequency * Double(index) / sampleRate)
            var value = Int16(sample * Double(Int16.max))
            withUnsafeBytes(of: &value) { buffer in
                sampleData.append(contentsOf: buffer)
            }
        }

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        var chunkSize = UInt32(36 + sampleData.count).littleEndian
        data.append(Data(bytes: &chunkSize, count: 4))
        data.append(contentsOf: "WAVEfmt ".utf8)
        var subchunk1Size: UInt32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: UInt16 = 1
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: UInt16 = 1
        data.append(Data(bytes: &numChannels, count: 2))
        var sampleRateUInt: UInt32 = UInt32(sampleRate)
        data.append(Data(bytes: &sampleRateUInt, count: 4))
        var byteRate: UInt32 = sampleRateUInt * UInt32(numChannels) * UInt32(2)
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: UInt16 = numChannels * 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: UInt16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))
        data.append(contentsOf: "data".utf8)
        var subchunk2Size = UInt32(sampleData.count).littleEndian
        data.append(Data(bytes: &subchunk2Size, count: 4))
        data.append(sampleData)

        return data
    }
}

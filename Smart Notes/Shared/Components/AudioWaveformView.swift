import SwiftUI

struct AudioWaveformView: View {
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.5, count: 50)
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<amplitudes.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4, height: amplitudes[index] * 100)
            }
        }
        .onAppear {
            // 애니메이션 시작
        }
    }
}

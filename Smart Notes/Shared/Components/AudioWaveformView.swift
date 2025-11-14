// AudioWaveformView.swift
import SwiftUI

struct AudioWaveformView: View {
    // 1. ViewModel로부터 현재 오디오 레벨을 받아옵니다.
    @ObservedObject var viewModel: RecordingViewModel
    
    let numberOfBars = 40 // 파형을 구성할 막대 개수
    
    var body: some View {
        HStack(spacing: 2) { // 막대 사이의 간격
            // 2. 각 막대에 대해 ForEach를 사용
            ForEach(0..<numberOfBars, id: \.self) { index in
                // 3. 오디오 레벨에 따라 막대 높이 계산
                // viewModel.currentAudioLevel은 0.0 ~ 1.0 사이의 값입니다.
                // 이 값을 0.1 ~ 1.0 사이로 변환하여 최소 높이를 보장하고, 애니메이션을 부드럽게 합니다.
                let barHeight = CGFloat(max(0.1, viewModel.currentAudioLevel)) * 80.0 // 80.0은 최대 높이 조절
                
                Capsule() // 둥근 모양의 막대
                    .fill(Color.blue)
                    .frame(height: barHeight) // 계산된 높이 적용
                    .animation(.easeOut(duration: 0.1), value: barHeight) // 부드러운 애니메이션
            }
        }
        .frame(height: 100) // 전체 파형 뷰의 높이 고정
    }
}

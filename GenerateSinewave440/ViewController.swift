//
//  ViewController.swift
//  GenerateSinewave440
//
//  Created by Masaki Horimoto on 2023/04/20.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    let audioEngine = AVAudioEngine()               //AudioEngineの生成
    let playerNode = AVAudioPlayerNode()            //playerの作成
    let session = AVAudioSession.sharedInstance()   //アプリでオーディオをどのように使用するかをシステムに伝えるオブジェクト

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func tapStartButton(_ sender: Any) {
        try! session.setCategory(.playback, mode: .default)                 //カテゴリをplayback,モードをデフォルトに設定
        try! session.setActive(true, options: .notifyOthersOnDeactivation)  //セッションをActiveに。OptionをnotifyOthersOnDeactivationに指定するとバックで再生しているアプリに再生を通知する
        
        let audioFormat = makeAudioFormat(sampleRate: 44100.0, channel: 2)  //サンプリング周波数44.1kHz、2channelで作成
        let buffer = makePCMBuffer(audioFormat: audioFormat)                //再生用Bufferを作成
        buffer.makeSinewave(frequency: 440, soundVolume: 1)                 //再生音(440Hz)作成
        
        audioEngine.attach(playerNode)  //Nodeを追加
        audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFormat)     //Nodeを接続（playerNode -> outputNode）
        
        audioEngine.prepare()
        try! audioEngine.start()
        
        if !playerNode.isPlaying {
            playerNode.play()
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)     //scheduleBufferのoptionsを.loopsにすることで再生し続ける
        }
    }

    @IBAction func tapFinishButton(_ sender: Any) {
        if playerNode.isPlaying {
            playerNode.stop()               //再生停止
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        try! session.setActive(false, options: .notifyOthersOnDeactivation)   //Audio sessionを停止。OptionをnotifyOthersOnDeactivationに指定するとバックで再生しているアプリに再生を通知する
    }
    
    //AudioFormatを作成
    func makeAudioFormat(sampleRate: Double, channel: Int) -> AVAudioFormat {
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: UInt32(channel)) else {
            fatalError("Error initializing AVAudioFormat")
        }
        return audioFormat
    }
    
    // 再生用のバッファを作成
    func makePCMBuffer(audioFormat: AVAudioFormat) -> AVAudioPCMBuffer {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioFormat.sampleRate)) else{
            fatalError("Error initializing AVAudioPCMBuffer")
        }
        buffer.frameLength = buffer.frameCapacity   //frameCapacityはバッファのpcmFormatのサンプリング周波数 サンプリング周波数を指定することで、1秒分の波形データを作成することにするために
        return buffer
    }
}

extension AVAudioPCMBuffer {
    // サイン波を作成
    func makeSinewave(frequency: Double, soundVolume: Double) {
        let channels = Int(self.format.channelCount)   //bufferのaudioFormatのチャンネル数を取得
        for ch in 0..<channels {    //各channel毎に処理
            let deltaTheta = 2.0 * .pi * frequency / self.format.sampleRate
            for i in 0..<Int(self.frameLength) {
                self.floatChannelData![ch][i] = Float(sin(deltaTheta * Double(i)) * soundVolume)
            }
        }
    }
}


//
//  AKPluckedStringAudioUnit.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import AVFoundation

public class AKPluckedStringAudioUnit: AKGeneratorAudioUnitBase {

    func setParameter(_ address: AKPluckedStringParameter, value: Double) {
        setParameterWithAddress(address.rawValue, value: Float(value))
    }

    func setParameterImmediately(_ address: AKPluckedStringParameter, value: Double) {
        setParameterImmediatelyWithAddress(address.rawValue, value: Float(value))
    }

    var frequency: Double = AKPluckedString.defaultFrequency {
        didSet { setParameter(.frequency, value: frequency) }
    }

    var amplitude: Double = AKPluckedString.defaultAmplitude {
        didSet { setParameter(.amplitude, value: amplitude) }
    }

    var rampDuration: Double = 0.0 {
        didSet { setParameter(.rampDuration, value: rampDuration) }
    }

    public override func initDSP(withSampleRate sampleRate: Double,
                                 channelCount count: AVAudioChannelCount) -> AKDSPRef {
        return createPluckedStringDSP(Int32(count), sampleRate)
    }

    public override init(componentDescription: AudioComponentDescription,
                  options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)

        let frequency = AUParameterTree.createParameter(
            identifier: "frequency",
            name: "Variable frequency. Values less than the initial frequency  will be doubled until it is greater than that.",
            address: AKPluckedStringParameter.frequency.rawValue,
            min: Float(AKPluckedString.frequencyRange.lowerBound),
            max: Float(AKPluckedString.frequencyRange.upperBound),
            unit: .hertz,
            flags: .default)
        let amplitude = AUParameterTree.createParameter(
            identifier: "amplitude",
            name: "Amplitude",
            address: AKPluckedStringParameter.amplitude.rawValue,
            min: Float(AKPluckedString.amplitudeRange.lowerBound),
            max: Float(AKPluckedString.amplitudeRange.upperBound),
            unit: .generic,
            flags: .default)
        
        setParameterTree(AUParameterTree.createTree(withChildren: [frequency, amplitude]))
        frequency.value = Float(AKPluckedString.defaultFrequency)
        amplitude.value = Float(AKPluckedString.defaultAmplitude)
    }

    public override var canProcessInPlace: Bool { return true }

}

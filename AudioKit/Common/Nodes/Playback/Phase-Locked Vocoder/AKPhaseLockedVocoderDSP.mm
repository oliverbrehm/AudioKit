// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#include "AudioKit.h"
#include "soundpipe.h"

class AKPhaseLockedVocoderDSP : public AKSoundpipeDSPBase {
private:
    sp_mincer *mincer;
    sp_ftbl *ftbl;
    std::vector<float> wavetable;

    ParameterRamper positionRamp;
    ParameterRamper amplitudeRamp;
    ParameterRamper pitchRatioRamp;

public:
    AKPhaseLockedVocoderDSP() {
        parameters[AKPhaseLockedVocoderParameterPosition] = &positionRamp;
        parameters[AKPhaseLockedVocoderParameterAmplitude] = &amplitudeRamp;
        parameters[AKPhaseLockedVocoderParameterPitchRatio] = &pitchRatioRamp;
    }

    void setWavetable(const float *table, size_t length, int index) {
        wavetable = std::vector<float>(table, table + length);
        if (!isInitialized) return;
        sp_ftbl_destroy(&ftbl);
        sp_ftbl_create(sp, &ftbl, wavetable.size());
        std::copy(wavetable.cbegin(), wavetable.cend(), ftbl->tbl);
        reset();
    }

    void init(int channelCount, double sampleRate) {
        AKSoundpipeDSPBase::init(channelCount, sampleRate);
        sp_ftbl_create(sp, &ftbl, wavetable.size());
        std::copy(wavetable.cbegin(), wavetable.cend(), ftbl->tbl);
        sp_mincer_create(&mincer);
        sp_mincer_init(sp, mincer, ftbl, 2048);
    }

    void deinit() {
        AKSoundpipeDSPBase::deinit();
        sp_ftbl_destroy(&ftbl);
        sp_mincer_destroy(&mincer);
    }

    void reset() {
        AKSoundpipeDSPBase::reset();
        if (!isInitialized) return;
        sp_mincer_init(sp, mincer, ftbl, 2048);
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) {

        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);

            mincer->time = positionRamp.getAndStep();
            mincer->amp = amplitudeRamp.getAndStep();
            mincer->pitch = pitchRatioRamp.getAndStep();

            float *outL = (float *)outputBufferLists[0]->mBuffers[0].mData  + frameOffset;
            float *outR = (float *)outputBufferLists[0]->mBuffers[1].mData + frameOffset;
            if (isStarted) {
                sp_mincer_compute(sp, mincer, NULL, outL);
                *outR = *outL;
            } else {
                *outL = 0;
                *outR = 0;
            }
        }
    }
};

AKDSPRef akPhaseLockedVocoderCreateDSP() {
    return new AKPhaseLockedVocoderDSP();
}

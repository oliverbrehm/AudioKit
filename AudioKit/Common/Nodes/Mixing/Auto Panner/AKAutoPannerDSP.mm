// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#import "AudioKit.h"
#include "soundpipe.h"

#import <vector>

class AKAutoPannerDSP : public AKSoundpipeDSPBase {
private:
    sp_osc *trem;
    sp_ftbl *tbl;
    sp_panst *panst;
    std::vector<float> wavetable;
    ParameterRamper frequencyRamp;
    ParameterRamper depthRamp;

public:
    AKAutoPannerDSP() {
        parameters[AKAutoPannerParameterFrequency] = &frequencyRamp;
        parameters[AKAutoPannerParameterDepth] = &depthRamp;
        bCanProcessInPlace = true;
    }

    void setWavetable(const float* table, size_t length, int index) {
        wavetable = std::vector<float>(table, table + length);
    }

    void init(int channelCount, double sampleRate) {
        AKSoundpipeDSPBase::init(channelCount, sampleRate);
        sp_ftbl_create(sp, &tbl, wavetable.size());
        std::copy(wavetable.cbegin(), wavetable.cend(), tbl->tbl);
        sp_osc_create(&trem);
        sp_osc_init(sp, trem, tbl, 0);
        sp_panst_create(&panst);
        sp_panst_init(sp, panst);
    }

    void deinit() {
        AKSoundpipeDSPBase::deinit();
        sp_osc_destroy(&trem);
        sp_panst_destroy(&panst);
        sp_ftbl_destroy(&tbl);
    }

    void process(uint32_t frameCount, uint32_t bufferOffset) {
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);

            trem->freq = frequencyRamp.getAndStep();
            trem->amp = 1;

            float temp = 0;
            float *tmpin[2];
            float *tmpout[2];
            for (int channel = 0; channel < channelCount; ++channel) {
                float *in  = (float *)inputBufferLists[0]->mBuffers[channel].mData  + frameOffset;
                float *out = (float *)outputBufferLists[0]->mBuffers[channel].mData + frameOffset;

                if (channel < 2) {
                    tmpin[channel] = in;
                    tmpout[channel] = out;
                }
                if (!isStarted) {
                    *out = *in;
                }
            }
            if (isStarted) {
                sp_osc_compute(sp, trem, NULL, &temp);
                panst->pan = (2.0 * temp - 1.0) * depthRamp.getAndStep();
                sp_panst_compute(sp, panst, tmpin[0], tmpin[1], tmpout[0], tmpout[1]);
            }
        }
    }

};

AKDSPRef akAutoPannerCreateDSP() {
    return new AKAutoPannerDSP();
}

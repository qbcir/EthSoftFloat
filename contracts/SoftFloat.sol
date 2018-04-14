pragma solidity ^0.4.11;

contract SoftFloat {

    function signF32UI(uint32 a) public pure returns(bool) {
        return (a >> 31) != 0;
    }

    function expF32UI(uint32 a) public pure returns(uint16) {
        return (uint16)((a >> 23) & 0xFF);
    }

    function fracF32UI(uint32 a) public pure returns(uint32) {
        return a & 0x007FFFFF;
    }

    function packToF32UI(bool sign, uint16 exp, uint32 sig) public pure returns (uint32) {
       return (uint32)(((uint32)(sign ? 1 : 0) << 31) + ((uint32)(exp) << 23) + sig);
    }

    function isNaNF32UI(uint32 a) public pure returns(bool) {
        return ((~a & 0x7F800000) == 0) && ((a & 0x007FFFFF) != 0);
    }

    function _shiftRightJam32(uint32 a, uint16 dist) internal pure returns (uint32) {
        uint32 tmp = (uint32)(a << (-dist & 31));
        return (dist < 31) ? ((a >> dist) | (tmp != 0 ? 1 : 0)) : (a != 0 ? 1 : 0);
    }

    function _shortShiftRightJam64(uint64 a, uint8 dist) internal pure returns (uint64) {
        return (a >> dist) | ((a & (((uint64)(1) << dist) - 1)) != 0 ? 1 : 0);
    }

    uint32 constant defaultNaNF32UI = 0x7FC00000;

    enum RoundingMode {
        even,
        minMag,
        min,
        max,
        maxMag,
        odd
    }

    enum DetectTininess {
        afterRounding,
        beforeRounding
    }

    RoundingMode _roundingMode = RoundingMode.even;
    DetectTininess _detectTininess = DetectTininess.beforeRounding;

    function _propagateNaNF32UI(uint32 /*uiA*/, uint32 /*uiB*/) internal pure returns (uint32) {
        return defaultNaNF32UI;
    }

    function _roundPackToF32(bool sign, int16 exp, uint32 sig) internal view returns (uint32) {
        uint8 roundIncrement = 0x40;
        if ((_roundingMode != RoundingMode.even) && (_roundingMode != RoundingMode.maxMag)) {
            roundIncrement = (_roundingMode == (sign ? RoundingMode.min : RoundingMode.max)) ? 0x7F : 0;
        }
        uint8 roundBits = (uint8)(sig & 0x7F);
        if (0xFD <= (uint16)(exp)) {
            if (exp < 0) {
                bool isTiny = (_detectTininess == DetectTininess.beforeRounding) || (exp < -1) || (sig + roundIncrement < 0x80000000);
                sig = _shiftRightJam32(sig, (uint8)(-exp));
                exp = 0;
                roundBits = (uint8)(sig & 0x7F);
                if (isTiny && roundBits != 0) {
                    //softfloat_raiseFlags( softfloat_flag_underflow );
                }
            } else if ((0xFD < exp) || (0x80000000 <= (sig + roundIncrement))) {
                //softfloat_raiseFlags(softfloat_flag_overflow | softfloat_flag_inexact );
                return packToF32UI(sign, 0xFF, 0) - (roundIncrement == 0 ? 1 : 0);
            }
        }
        sig = (sig + roundIncrement) >> 7;
        if (roundBits != 0) {
            //softfloat_exceptionFlags |= softfloat_flag_inexact;
            if (_roundingMode == RoundingMode.odd ) {
                return packToF32UI(sign, (uint16)(exp), sig | 1);
            }
        }
        sig &= ~(uint32)(((roundBits ^ 0x40) == 0 ? 1 : 0) & (_roundingMode == RoundingMode.even ? 1 : 0));
        if (sig == 0) {
            exp = 0;
        }
        return packToF32UI(sign, (uint16)(exp), sig);
    }

    function _normRoundPackToF32(bool sign, int16 exp, uint32 sig) internal view returns (uint32) {
        int8 shiftDist = (int8)(_countLeadingZeros32(sig)) - 1;
        exp -= shiftDist;
        if ((shiftDist >= 7) && ((uint16)(exp) < 0xFD)) {
            return packToF32UI(sign, (uint16)(sig != 0 ? exp : 0), sig<<(shiftDist - 7));
        } else {
            return _roundPackToF32(sign, exp, sig << shiftDist);
        }
    }

    uint8[256] _countLeadingZeros8 = [
        8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ];

    function _countLeadingZeros32(uint32 a) internal view returns (uint8) {
        uint8 count = 0;
        if (a < 0x10000) {
            count = 16;
            a <<= 16;
        }
        if (a < 0x1000000) {
            count += 8;
            a <<= 8;
        }
        count += _countLeadingZeros8[a>>24];
        return count;
    }

    function _addMagsF32(uint32 uiA, uint32 uiB ) internal view returns (uint32) {
        bool signZ;
        uint16 expZ;
        uint32 sigZ;

        uint16 expA = expF32UI(uiA);
        uint32 sigA = fracF32UI(uiA);
        uint16 expB = expF32UI(uiB);
        uint32 sigB = fracF32UI(uiB);

        uint16 expDiff = expA - expB;

        if (expDiff == 0) {
            if (expA == 0) {
                return uiA + sigB;
            } else if (expA == 0xFF) {
                if ((sigA | sigB) != 0) {
                    return _propagateNaNF32UI(uiA, uiB);
                } else {
                    return uiA;
                }
            } else {
                signZ = signF32UI(uiA);
                expZ = expA;
                sigZ = 0x01000000 + sigA + sigB;
                if (((sigZ & 1) == 0) && (expZ < 0xFE)) {
                    return packToF32UI(signZ, expZ, sigZ >> 1);
                } else {
                    sigZ <<= 6;
                }
            }
        } else {
            signZ = signF32UI(uiA);
            sigA <<= 6;
            sigB <<= 6;
            if (expDiff < 0) {
                if (expB == 0xFF) {
                    if (sigB != 0) {
                        return _propagateNaNF32UI(uiA, uiB);
                    } else {
                        return packToF32UI(signZ, 0xFF, 0);
                    }
                } else {
                    expZ = expB;
                    sigA += (expA != 0) ? 0x20000000 : sigA;
                    sigA = _shiftRightJam32(sigA, -expDiff);
                }
            } else {
                if (expA == 0xFF) {
                    if (sigA != 0) {
                        return _propagateNaNF32UI(uiA, uiB);
                    } else {
                        return uiA;
                    }
                } else {
                    expZ = expA;
                    sigB += (expB != 0) ? 0x20000000 : sigB;
                    sigB = _shiftRightJam32(sigB, expDiff);
                }
            }
            sigZ = 0x20000000 + sigA + sigB;
            if (sigZ < 0x40000000) {
                --expZ;
                sigZ <<= 1;
            }
        }
        return _roundPackToF32(signZ, (int16)(expZ), sigZ);
    }

    function _subMagsF32(uint32 uiA, uint32 uiB) internal view returns (uint32) {
        bool signZ;
        int8 shiftDist;
        int16 expZ;
        uint32 sigX;
        uint32 sigY;

        int16 expA = (int16)(expF32UI(uiA));
        uint32 sigA = fracF32UI(uiA);
        int16 expB = (int16)(expF32UI(uiB));
        uint32 sigB = fracF32UI(uiB);

        if (expA == expB) {
            if (expA == 0xFF) {
                if ((sigA | sigB) != 0) {
                    return _propagateNaNF32UI(uiA, uiB);
                } else {
                    //softfloat_raiseFlags( softfloat_flag_invalid );
                    return defaultNaNF32UI;
                }
            } else {
                int32 sigDiff = (int32)(sigA - sigB);
                if (sigDiff == 0) {
                    return packToF32UI(_roundingMode == RoundingMode.min, 0, 0 );
                } else {
                    if (expA != 0) {
                        --expA;
                    }
                    signZ = signF32UI(uiA);
                    if (sigDiff < 0) {
                        signZ = !signZ;
                        sigDiff = -sigDiff;
                    }
                    shiftDist = (int8)(_countLeadingZeros32((uint32)(sigDiff))) - 8;
                    expZ = expA - shiftDist;
                    if (expZ < 0) {
                        shiftDist = (int8)(expA);
                        expZ = 0;
                    }
                    return packToF32UI(signZ, (uint16)(expZ), (uint32)(sigDiff << shiftDist));
                }
            }
        } else {
            signZ = signF32UI(uiA);
            sigA <<= 7;
            sigB <<= 7;
            if (expA < expB) {
                signZ = !signZ;
                if (expB == 0xFF) {
                    return sigB != 0 ? _propagateNaNF32UI(uiA, uiB) : packToF32UI(signZ, 0xFF, 0);
                } else {
                    expZ = expB - 1;
                    sigX = sigB | 0x40000000;
                    sigY = sigA + (expA != 0 ? 0x40000000 : sigA);
                    return _normRoundPackToF32(signZ, expZ, sigX - _shiftRightJam32(sigY, (uint16)(expB - expA)));
                }
            } else {
                if (expA == 0xFF) {
                    return sigA != 0 ? _propagateNaNF32UI(uiA, uiB) : uiA;
                } else {
                    expZ = expA - 1;
                    sigX = sigA | 0x40000000;
                    sigY = sigB + (expB != 0 ? 0x40000000 : sigB);
                    return _normRoundPackToF32(signZ, expZ, sigX - _shiftRightJam32(sigY, (uint16)(expA - expB)));
                }
            }
        }
    }

    function f32_add(uint32 uiA, uint32 uiB) public view returns (uint32) {
        if (signF32UI(uiA ^ uiB)) {
            return _subMagsF32(uiA, uiB);
        } else {
            return _addMagsF32(uiA, uiB);
        }
    }

    function f32_sub(uint32 uiA, uint32 uiB) public view returns (uint32) {
        if (signF32UI(uiA ^ uiB)) {
            return _addMagsF32(uiA, uiB);
        } else {
            return _subMagsF32(uiA, uiB);
        }
    }

    function _normSubnormalF32Sig(uint32 sig) internal view returns (int16, uint32) {
        int8 shiftDist = (int8)(_countLeadingZeros32(sig)) - 8;
        return ((int16)(1) - shiftDist, sig << shiftDist);
    }

    function f32_mul(uint32 uiA, uint32 uiB) public view returns (uint32) {
        bool signA = signF32UI(uiA);
        int16 expA  = (int16)(expF32UI(uiA));
        uint32 sigA  = fracF32UI(uiA);
        bool signB = signF32UI(uiB);
        int16 expB  = (int16)(expF32UI(uiB));
        uint32 sigB  = fracF32UI(uiB);
        bool signZ = signA != signB;
        uint32 magBits;

        if (expA == 0xFF) {
            if (sigA != 0 || ((expB == 0xFF) && (sigB != 0))) {
                return _propagateNaNF32UI(uiA, uiB);
            }
            magBits = (uint32)(expB) | sigB;
            if (magBits == 0) {
                //softfloat_raiseFlags( softfloat_flag_invalid );
                return defaultNaNF32UI;
            } else {
                return packToF32UI(signZ, 0xFF, 0);
            }
        }
        if (expB == 0xFF) {
            if (sigB != 0) {
                return _propagateNaNF32UI(uiA, uiB);
            }
            magBits = (uint32)(expA) | sigA;
            if (magBits == 0) {
                //softfloat_raiseFlags( softfloat_flag_invalid );
                return defaultNaNF32UI;
            } else {
                return packToF32UI(signZ, 0xFF, 0);
            }
        }
        if (expA == 0) {
            if (sigA == 0) {
                return packToF32UI(signZ, 0, 0);
            }
            (expA, sigA) = _normSubnormalF32Sig(sigA);
        }
        if (expB == 0) {
            if (sigB == 0) {
                return packToF32UI(signZ, 0, 0);
            }
            (expB, sigB) = _normSubnormalF32Sig(sigB);
        }
        int16 expZ = expA + expB - 0x7F;
        sigA = (sigA | 0x00800000) << 7;
        sigB = (sigB | 0x00800000) << 8;
        uint32 sigZ = (uint32)(_shortShiftRightJam64((uint64)(sigA) * sigB, 32));
        if (sigZ < 0x40000000) {
            --expZ;
            sigZ <<= 1;
        }
        return _roundPackToF32(signZ, expZ, sigZ);
    }

    function f32_div(uint32 uiA, uint32 uiB) public view returns (uint32) {
        bool signA = signF32UI( uiA );
        int16 expA = (int16)(expF32UI(uiA));
        uint32 sigA = fracF32UI(uiA);
        bool signB = signF32UI(uiB);
        int16 expB  = (int16)(expF32UI(uiB));
        uint32 sigB = fracF32UI(uiB);
        bool signZ = signA != signB;

        if (expA == 0xFF) {
            if (sigA != 0) {
                return _propagateNaNF32UI(uiA, uiB);
            }
            if (expB == 0xFF) {
                if (sigB != 0) {
                    return _propagateNaNF32UI(uiA, uiB);
                }
                //softfloat_raiseFlags( softfloat_flag_invalid );
                return defaultNaNF32UI;
            }
            return packToF32UI(signZ, 0xFF, 0); // infinity
        }

        if (expB == 0xFF) {
            if (sigB != 0) {
                return _propagateNaNF32UI(uiA, uiB);
            }
            return packToF32UI(signZ, 0, 0);
        }

        if (expB == 0) {
            if (sigB == 0) {
                if (((uint16)(expA) | sigA) == 0) {
                    //softfloat_raiseFlags( softfloat_flag_invalid );
                    return defaultNaNF32UI;
                }
                //softfloat_raiseFlags( softfloat_flag_infinite );
                return packToF32UI(signZ, 0xFF, 0); // infinity
            }
            (expB, sigB) = _normSubnormalF32Sig(sigB);
        }

        if (expA == 0) {
            if (sigA == 0) {
                return packToF32UI(signZ, 0, 0); // zero
            }
            (expA, sigA) = _normSubnormalF32Sig(sigA);
        }

        int16 expZ = expA - expB + 0x7E;
        sigA |= 0x00800000;
        sigB |= 0x00800000;

        uint64 sig64A;
        if (sigA < sigB) {
            --expZ;
            sig64A = (uint64)(sigA) << 31;
        } else {
            sig64A = (uint64)(sigA) << 30;
        }

        uint32 sigZ = (uint32)(sig64A / sigB);
        if ((sigZ & 0x3F) == 0) {
            sigZ |= (((uint64)(sigB) * (uint64)(sigZ) != sig64A) ? 1 : 0);
        }

        return _roundPackToF32(signZ, expZ, sigZ);
    }
}

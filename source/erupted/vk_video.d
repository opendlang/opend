/**
 * Dlang vulkan type definitions
 *
 * Copyright: Copyright 2015-2016 The Khronos Group Inc.; Copyright 2016 Alex Parrill, Peter Particle.
 * License:   $(https://opensource.org/licenses/MIT, MIT License).
 * Authors: Copyright 2016 Alex Parrill, Peter Particle
 */
module erupted.vk_video;

import std.bitmanip : bitfields;

nothrow @nogc:

// defined in vk_platform.h
alias uint8_t   = ubyte;
alias uint16_t  = ushort;
alias uint32_t  = uint;
alias uint64_t  = ulong;
alias int8_t    = byte;
alias int16_t   = short;
alias int32_t   = int;
alias int64_t   = long;


// - vulkan_video_codecs_common -
enum vulkan_video_codecs_common = 1;

pure uint VK_MAKE_VIDEO_STD_VERSION( uint major, uint minor, uint patch ) { return ( major << 22 ) | ( minor << 12 ) | patch; }


// - vulkan_video_codec_h264std -
enum vulkan_video_codec_h264std = 1;

enum STD_VIDEO_H264_CPB_CNT_LIST_SIZE = 32;
enum STD_VIDEO_H264_SCALING_LIST_4X4_NUM_LISTS = 6;
enum STD_VIDEO_H264_SCALING_LIST_4X4_NUM_ELEMENTS = 16;
enum STD_VIDEO_H264_SCALING_LIST_8X8_NUM_LISTS = 6;
enum STD_VIDEO_H264_SCALING_LIST_8X8_NUM_ELEMENTS = 64;
enum STD_VIDEO_H264_MAX_NUM_LIST_REF = 32;
enum STD_VIDEO_H264_MAX_CHROMA_PLANES = 2;

enum StdVideoH264ChromaFormatIdc {
    STD_VIDEO_H264_CHROMA_FORMAT_IDC_MONOCHROME  = 0,
    STD_VIDEO_H264_CHROMA_FORMAT_IDC_420         = 1,
    STD_VIDEO_H264_CHROMA_FORMAT_IDC_422         = 2,
    STD_VIDEO_H264_CHROMA_FORMAT_IDC_444         = 3,
    STD_VIDEO_H264_CHROMA_FORMAT_IDC_INVALID     = 0x7FFFFFFF,
    STD_VIDEO_H2_64_CHROMA_FORMAT_IDC_MAX_ENUM   = 0x7FFFFFFF
}

enum STD_VIDEO_H264_CHROMA_FORMAT_IDC_MONOCHROME = StdVideoH264ChromaFormatIdc.STD_VIDEO_H264_CHROMA_FORMAT_IDC_MONOCHROME;
enum STD_VIDEO_H264_CHROMA_FORMAT_IDC_420        = StdVideoH264ChromaFormatIdc.STD_VIDEO_H264_CHROMA_FORMAT_IDC_420;
enum STD_VIDEO_H264_CHROMA_FORMAT_IDC_422        = StdVideoH264ChromaFormatIdc.STD_VIDEO_H264_CHROMA_FORMAT_IDC_422;
enum STD_VIDEO_H264_CHROMA_FORMAT_IDC_444        = StdVideoH264ChromaFormatIdc.STD_VIDEO_H264_CHROMA_FORMAT_IDC_444;
enum STD_VIDEO_H264_CHROMA_FORMAT_IDC_INVALID    = StdVideoH264ChromaFormatIdc.STD_VIDEO_H264_CHROMA_FORMAT_IDC_INVALID;
enum STD_VIDEO_H2_64_CHROMA_FORMAT_IDC_MAX_ENUM  = StdVideoH264ChromaFormatIdc.STD_VIDEO_H2_64_CHROMA_FORMAT_IDC_MAX_ENUM;

enum StdVideoH264ProfileIdc {
    STD_VIDEO_H264_PROFILE_IDC_BASELINE                  = 66,
    STD_VIDEO_H264_PROFILE_IDC_MAIN                      = 77,
    STD_VIDEO_H264_PROFILE_IDC_HIGH                      = 100,
    STD_VIDEO_H264_PROFILE_IDC_HIGH_444_PREDICTIVE       = 244,
    STD_VIDEO_H264_PROFILE_IDC_INVALID                   = 0x7FFFFFFF,
    STD_VIDEO_H2_64_PROFILE_IDC_MAX_ENUM                 = 0x7FFFFFFF
}

enum STD_VIDEO_H264_PROFILE_IDC_BASELINE                 = StdVideoH264ProfileIdc.STD_VIDEO_H264_PROFILE_IDC_BASELINE;
enum STD_VIDEO_H264_PROFILE_IDC_MAIN                     = StdVideoH264ProfileIdc.STD_VIDEO_H264_PROFILE_IDC_MAIN;
enum STD_VIDEO_H264_PROFILE_IDC_HIGH                     = StdVideoH264ProfileIdc.STD_VIDEO_H264_PROFILE_IDC_HIGH;
enum STD_VIDEO_H264_PROFILE_IDC_HIGH_444_PREDICTIVE      = StdVideoH264ProfileIdc.STD_VIDEO_H264_PROFILE_IDC_HIGH_444_PREDICTIVE;
enum STD_VIDEO_H264_PROFILE_IDC_INVALID                  = StdVideoH264ProfileIdc.STD_VIDEO_H264_PROFILE_IDC_INVALID;
enum STD_VIDEO_H2_64_PROFILE_IDC_MAX_ENUM                = StdVideoH264ProfileIdc.STD_VIDEO_H2_64_PROFILE_IDC_MAX_ENUM;

enum StdVideoH264LevelIdc {
    STD_VIDEO_H264_LEVEL_IDC_1_0         = 0,
    STD_VIDEO_H264_LEVEL_IDC_1_1         = 1,
    STD_VIDEO_H264_LEVEL_IDC_1_2         = 2,
    STD_VIDEO_H264_LEVEL_IDC_1_3         = 3,
    STD_VIDEO_H264_LEVEL_IDC_2_0         = 4,
    STD_VIDEO_H264_LEVEL_IDC_2_1         = 5,
    STD_VIDEO_H264_LEVEL_IDC_2_2         = 6,
    STD_VIDEO_H264_LEVEL_IDC_3_0         = 7,
    STD_VIDEO_H264_LEVEL_IDC_3_1         = 8,
    STD_VIDEO_H264_LEVEL_IDC_3_2         = 9,
    STD_VIDEO_H264_LEVEL_IDC_4_0         = 10,
    STD_VIDEO_H264_LEVEL_IDC_4_1         = 11,
    STD_VIDEO_H264_LEVEL_IDC_4_2         = 12,
    STD_VIDEO_H264_LEVEL_IDC_5_0         = 13,
    STD_VIDEO_H264_LEVEL_IDC_5_1         = 14,
    STD_VIDEO_H264_LEVEL_IDC_5_2         = 15,
    STD_VIDEO_H264_LEVEL_IDC_6_0         = 16,
    STD_VIDEO_H264_LEVEL_IDC_6_1         = 17,
    STD_VIDEO_H264_LEVEL_IDC_6_2         = 18,
    STD_VIDEO_H264_LEVEL_IDC_INVALID     = 0x7FFFFFFF,
    STD_VIDEO_H2_64_LEVEL_IDC_MAX_ENUM   = 0x7FFFFFFF
}

enum STD_VIDEO_H264_LEVEL_IDC_1_0        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_1_0;
enum STD_VIDEO_H264_LEVEL_IDC_1_1        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_1_1;
enum STD_VIDEO_H264_LEVEL_IDC_1_2        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_1_2;
enum STD_VIDEO_H264_LEVEL_IDC_1_3        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_1_3;
enum STD_VIDEO_H264_LEVEL_IDC_2_0        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_2_0;
enum STD_VIDEO_H264_LEVEL_IDC_2_1        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_2_1;
enum STD_VIDEO_H264_LEVEL_IDC_2_2        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_2_2;
enum STD_VIDEO_H264_LEVEL_IDC_3_0        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_3_0;
enum STD_VIDEO_H264_LEVEL_IDC_3_1        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_3_1;
enum STD_VIDEO_H264_LEVEL_IDC_3_2        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_3_2;
enum STD_VIDEO_H264_LEVEL_IDC_4_0        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_4_0;
enum STD_VIDEO_H264_LEVEL_IDC_4_1        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_4_1;
enum STD_VIDEO_H264_LEVEL_IDC_4_2        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_4_2;
enum STD_VIDEO_H264_LEVEL_IDC_5_0        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_5_0;
enum STD_VIDEO_H264_LEVEL_IDC_5_1        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_5_1;
enum STD_VIDEO_H264_LEVEL_IDC_5_2        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_5_2;
enum STD_VIDEO_H264_LEVEL_IDC_6_0        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_6_0;
enum STD_VIDEO_H264_LEVEL_IDC_6_1        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_6_1;
enum STD_VIDEO_H264_LEVEL_IDC_6_2        = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_6_2;
enum STD_VIDEO_H264_LEVEL_IDC_INVALID    = StdVideoH264LevelIdc.STD_VIDEO_H264_LEVEL_IDC_INVALID;
enum STD_VIDEO_H2_64_LEVEL_IDC_MAX_ENUM  = StdVideoH264LevelIdc.STD_VIDEO_H2_64_LEVEL_IDC_MAX_ENUM;

enum StdVideoH264PocType {
    STD_VIDEO_H264_POC_TYPE_0            = 0,
    STD_VIDEO_H264_POC_TYPE_1            = 1,
    STD_VIDEO_H264_POC_TYPE_2            = 2,
    STD_VIDEO_H264_POC_TYPE_INVALID      = 0x7FFFFFFF,
    STD_VIDEO_H2_64_POC_TYPE_MAX_ENUM    = 0x7FFFFFFF
}

enum STD_VIDEO_H264_POC_TYPE_0           = StdVideoH264PocType.STD_VIDEO_H264_POC_TYPE_0;
enum STD_VIDEO_H264_POC_TYPE_1           = StdVideoH264PocType.STD_VIDEO_H264_POC_TYPE_1;
enum STD_VIDEO_H264_POC_TYPE_2           = StdVideoH264PocType.STD_VIDEO_H264_POC_TYPE_2;
enum STD_VIDEO_H264_POC_TYPE_INVALID     = StdVideoH264PocType.STD_VIDEO_H264_POC_TYPE_INVALID;
enum STD_VIDEO_H2_64_POC_TYPE_MAX_ENUM   = StdVideoH264PocType.STD_VIDEO_H2_64_POC_TYPE_MAX_ENUM;

enum StdVideoH264AspectRatioIdc {
    STD_VIDEO_H264_ASPECT_RATIO_IDC_UNSPECIFIED          = 0,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_SQUARE               = 1,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_12_11                = 2,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_10_11                = 3,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_16_11                = 4,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_40_33                = 5,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_24_11                = 6,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_20_11                = 7,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_32_11                = 8,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_80_33                = 9,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_18_11                = 10,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_15_11                = 11,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_64_33                = 12,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_160_99               = 13,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_4_3                  = 14,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_3_2                  = 15,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_2_1                  = 16,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_EXTENDED_SAR         = 255,
    STD_VIDEO_H264_ASPECT_RATIO_IDC_INVALID              = 0x7FFFFFFF,
    STD_VIDEO_H2_64_ASPECT_RATIO_IDC_MAX_ENUM            = 0x7FFFFFFF
}

enum STD_VIDEO_H264_ASPECT_RATIO_IDC_UNSPECIFIED         = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_UNSPECIFIED;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_SQUARE              = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_SQUARE;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_12_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_12_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_10_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_10_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_16_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_16_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_40_33               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_40_33;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_24_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_24_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_20_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_20_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_32_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_32_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_80_33               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_80_33;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_18_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_18_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_15_11               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_15_11;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_64_33               = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_64_33;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_160_99              = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_160_99;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_4_3                 = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_4_3;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_3_2                 = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_3_2;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_2_1                 = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_2_1;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_EXTENDED_SAR        = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_EXTENDED_SAR;
enum STD_VIDEO_H264_ASPECT_RATIO_IDC_INVALID             = StdVideoH264AspectRatioIdc.STD_VIDEO_H264_ASPECT_RATIO_IDC_INVALID;
enum STD_VIDEO_H2_64_ASPECT_RATIO_IDC_MAX_ENUM           = StdVideoH264AspectRatioIdc.STD_VIDEO_H2_64_ASPECT_RATIO_IDC_MAX_ENUM;

enum StdVideoH264WeightedBipredIdc {
    STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_DEFAULT   = 0,
    STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_EXPLICIT  = 1,
    STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_IMPLICIT  = 2,
    STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_INVALID   = 0x7FFFFFFF,
    STD_VIDEO_H2_64_WEIGHTED_BIPRED_IDC_MAX_ENUM = 0x7FFFFFFF
}

enum STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_DEFAULT  = StdVideoH264WeightedBipredIdc.STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_DEFAULT;
enum STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_EXPLICIT = StdVideoH264WeightedBipredIdc.STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_EXPLICIT;
enum STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_IMPLICIT = StdVideoH264WeightedBipredIdc.STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_IMPLICIT;
enum STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_INVALID  = StdVideoH264WeightedBipredIdc.STD_VIDEO_H264_WEIGHTED_BIPRED_IDC_INVALID;
enum STD_VIDEO_H2_64_WEIGHTED_BIPRED_IDC_MAX_ENUM = StdVideoH264WeightedBipredIdc.STD_VIDEO_H2_64_WEIGHTED_BIPRED_IDC_MAX_ENUM;

enum StdVideoH264ModificationOfPicNumsIdc {
    STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_SHORT_TERM_SUBTRACT      = 0,
    STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_SHORT_TERM_ADD           = 1,
    STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_LONG_TERM                = 2,
    STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_END                      = 3,
    STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_INVALID                  = 0x7FFFFFFF,
    STD_VIDEO_H2_64_MODIFICATION_OFPIC_NUMS_IDC_MAX_ENUM                 = 0x7FFFFFFF
}

enum STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_SHORT_TERM_SUBTRACT     = StdVideoH264ModificationOfPicNumsIdc.STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_SHORT_TERM_SUBTRACT;
enum STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_SHORT_TERM_ADD          = StdVideoH264ModificationOfPicNumsIdc.STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_SHORT_TERM_ADD;
enum STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_LONG_TERM               = StdVideoH264ModificationOfPicNumsIdc.STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_LONG_TERM;
enum STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_END                     = StdVideoH264ModificationOfPicNumsIdc.STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_END;
enum STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_INVALID                 = StdVideoH264ModificationOfPicNumsIdc.STD_VIDEO_H264_MODIFICATION_OF_PIC_NUMS_IDC_INVALID;
enum STD_VIDEO_H2_64_MODIFICATION_OFPIC_NUMS_IDC_MAX_ENUM                = StdVideoH264ModificationOfPicNumsIdc.STD_VIDEO_H2_64_MODIFICATION_OFPIC_NUMS_IDC_MAX_ENUM;

enum StdVideoH264MemMgmtControlOp {
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_END                               = 0,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_SHORT_TERM                 = 1,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_LONG_TERM                  = 2,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_MARK_LONG_TERM                    = 3,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_SET_MAX_LONG_TERM_INDEX           = 4,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_ALL                        = 5,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_MARK_CURRENT_AS_LONG_TERM         = 6,
    STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_INVALID                           = 0x7FFFFFFF,
    STD_VIDEO_H2_64_MEM_MGMT_CONTROL_OP_MAX_ENUM                         = 0x7FFFFFFF
}

enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_END                              = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_END;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_SHORT_TERM                = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_SHORT_TERM;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_LONG_TERM                 = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_LONG_TERM;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_MARK_LONG_TERM                   = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_MARK_LONG_TERM;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_SET_MAX_LONG_TERM_INDEX          = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_SET_MAX_LONG_TERM_INDEX;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_ALL                       = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_UNMARK_ALL;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_MARK_CURRENT_AS_LONG_TERM        = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_MARK_CURRENT_AS_LONG_TERM;
enum STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_INVALID                          = StdVideoH264MemMgmtControlOp.STD_VIDEO_H264_MEM_MGMT_CONTROL_OP_INVALID;
enum STD_VIDEO_H2_64_MEM_MGMT_CONTROL_OP_MAX_ENUM                        = StdVideoH264MemMgmtControlOp.STD_VIDEO_H2_64_MEM_MGMT_CONTROL_OP_MAX_ENUM;

enum StdVideoH264CabacInitIdc {
    STD_VIDEO_H264_CABAC_INIT_IDC_0              = 0,
    STD_VIDEO_H264_CABAC_INIT_IDC_1              = 1,
    STD_VIDEO_H264_CABAC_INIT_IDC_2              = 2,
    STD_VIDEO_H264_CABAC_INIT_IDC_INVALID        = 0x7FFFFFFF,
    STD_VIDEO_H2_64_CABAC_INIT_IDC_MAX_ENUM      = 0x7FFFFFFF
}

enum STD_VIDEO_H264_CABAC_INIT_IDC_0             = StdVideoH264CabacInitIdc.STD_VIDEO_H264_CABAC_INIT_IDC_0;
enum STD_VIDEO_H264_CABAC_INIT_IDC_1             = StdVideoH264CabacInitIdc.STD_VIDEO_H264_CABAC_INIT_IDC_1;
enum STD_VIDEO_H264_CABAC_INIT_IDC_2             = StdVideoH264CabacInitIdc.STD_VIDEO_H264_CABAC_INIT_IDC_2;
enum STD_VIDEO_H264_CABAC_INIT_IDC_INVALID       = StdVideoH264CabacInitIdc.STD_VIDEO_H264_CABAC_INIT_IDC_INVALID;
enum STD_VIDEO_H2_64_CABAC_INIT_IDC_MAX_ENUM     = StdVideoH264CabacInitIdc.STD_VIDEO_H2_64_CABAC_INIT_IDC_MAX_ENUM;

enum StdVideoH264DisableDeblockingFilterIdc {
    STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_DISABLED        = 0,
    STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_ENABLED         = 1,
    STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_PARTIAL         = 2,
    STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_INVALID         = 0x7FFFFFFF,
    STD_VIDEO_H2_64_DISABLE_DEBLOCKING_FILTER_IDC_MAX_ENUM       = 0x7FFFFFFF
}

enum STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_DISABLED       = StdVideoH264DisableDeblockingFilterIdc.STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_DISABLED;
enum STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_ENABLED        = StdVideoH264DisableDeblockingFilterIdc.STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_ENABLED;
enum STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_PARTIAL        = StdVideoH264DisableDeblockingFilterIdc.STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_PARTIAL;
enum STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_INVALID        = StdVideoH264DisableDeblockingFilterIdc.STD_VIDEO_H264_DISABLE_DEBLOCKING_FILTER_IDC_INVALID;
enum STD_VIDEO_H2_64_DISABLE_DEBLOCKING_FILTER_IDC_MAX_ENUM      = StdVideoH264DisableDeblockingFilterIdc.STD_VIDEO_H2_64_DISABLE_DEBLOCKING_FILTER_IDC_MAX_ENUM;

enum StdVideoH264SliceType {
    STD_VIDEO_H264_SLICE_TYPE_P          = 0,
    STD_VIDEO_H264_SLICE_TYPE_B          = 1,
    STD_VIDEO_H264_SLICE_TYPE_I          = 2,
    STD_VIDEO_H264_SLICE_TYPE_INVALID    = 0x7FFFFFFF,
    STD_VIDEO_H2_64_SLICE_TYPE_MAX_ENUM  = 0x7FFFFFFF
}

enum STD_VIDEO_H264_SLICE_TYPE_P         = StdVideoH264SliceType.STD_VIDEO_H264_SLICE_TYPE_P;
enum STD_VIDEO_H264_SLICE_TYPE_B         = StdVideoH264SliceType.STD_VIDEO_H264_SLICE_TYPE_B;
enum STD_VIDEO_H264_SLICE_TYPE_I         = StdVideoH264SliceType.STD_VIDEO_H264_SLICE_TYPE_I;
enum STD_VIDEO_H264_SLICE_TYPE_INVALID   = StdVideoH264SliceType.STD_VIDEO_H264_SLICE_TYPE_INVALID;
enum STD_VIDEO_H2_64_SLICE_TYPE_MAX_ENUM = StdVideoH264SliceType.STD_VIDEO_H2_64_SLICE_TYPE_MAX_ENUM;

enum StdVideoH264PictureType {
    STD_VIDEO_H264_PICTURE_TYPE_P        = 0,
    STD_VIDEO_H264_PICTURE_TYPE_B        = 1,
    STD_VIDEO_H264_PICTURE_TYPE_I        = 2,
    STD_VIDEO_H264_PICTURE_TYPE_IDR      = 5,
    STD_VIDEO_H264_PICTURE_TYPE_INVALID  = 0x7FFFFFFF,
    STD_VIDEO_H2_64_PICTURE_TYPE_MAX_ENUM = 0x7FFFFFFF
}

enum STD_VIDEO_H264_PICTURE_TYPE_P       = StdVideoH264PictureType.STD_VIDEO_H264_PICTURE_TYPE_P;
enum STD_VIDEO_H264_PICTURE_TYPE_B       = StdVideoH264PictureType.STD_VIDEO_H264_PICTURE_TYPE_B;
enum STD_VIDEO_H264_PICTURE_TYPE_I       = StdVideoH264PictureType.STD_VIDEO_H264_PICTURE_TYPE_I;
enum STD_VIDEO_H264_PICTURE_TYPE_IDR     = StdVideoH264PictureType.STD_VIDEO_H264_PICTURE_TYPE_IDR;
enum STD_VIDEO_H264_PICTURE_TYPE_INVALID = StdVideoH264PictureType.STD_VIDEO_H264_PICTURE_TYPE_INVALID;
enum STD_VIDEO_H2_64_PICTURE_TYPE_MAX_ENUM = StdVideoH264PictureType.STD_VIDEO_H2_64_PICTURE_TYPE_MAX_ENUM;

enum StdVideoH264NonVclNaluType {
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_SPS                 = 0,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_PPS                 = 1,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_AUD                 = 2,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_PREFIX              = 3,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_END_OF_SEQUENCE     = 4,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_END_OF_STREAM       = 5,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_PRECODED            = 6,
    STD_VIDEO_H264_NON_VCL_NALU_TYPE_INVALID             = 0x7FFFFFFF,
    STD_VIDEO_H2_64_NON_VCL_NALU_TYPE_MAX_ENUM           = 0x7FFFFFFF
}

enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_SPS                = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_SPS;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_PPS                = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_PPS;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_AUD                = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_AUD;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_PREFIX             = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_PREFIX;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_END_OF_SEQUENCE    = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_END_OF_SEQUENCE;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_END_OF_STREAM      = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_END_OF_STREAM;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_PRECODED           = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_PRECODED;
enum STD_VIDEO_H264_NON_VCL_NALU_TYPE_INVALID            = StdVideoH264NonVclNaluType.STD_VIDEO_H264_NON_VCL_NALU_TYPE_INVALID;
enum STD_VIDEO_H2_64_NON_VCL_NALU_TYPE_MAX_ENUM          = StdVideoH264NonVclNaluType.STD_VIDEO_H2_64_NON_VCL_NALU_TYPE_MAX_ENUM;

struct StdVideoH264SpsVuiFlags {
}

struct StdVideoH264HrdParameters {
    uint8_t                                       cpb_cnt_minus1;
    uint8_t                                       bit_rate_scale;
    uint8_t                                       cpb_size_scale;
    uint8_t                                       reserved1;
    uint32_t[ STD_VIDEO_H264_CPB_CNT_LIST_SIZE ]  bit_rate_value_minus1;
    uint32_t[ STD_VIDEO_H264_CPB_CNT_LIST_SIZE ]  cpb_size_value_minus1;
    uint8_t[ STD_VIDEO_H264_CPB_CNT_LIST_SIZE ]   cbr_flag;
    uint32_t                                      initial_cpb_removal_delay_length_minus1;
    uint32_t                                      cpb_removal_delay_length_minus1;
    uint32_t                                      dpb_output_delay_length_minus1;
    uint32_t                                      time_offset_length;
}

struct StdVideoH264SequenceParameterSetVui {
    StdVideoH264SpsVuiFlags              flags;
    StdVideoH264AspectRatioIdc           aspect_ratio_idc;
    uint16_t                             sar_width;
    uint16_t                             sar_height;
    uint8_t                              video_format;
    uint8_t                              colour_primaries;
    uint8_t                              transfer_characteristics;
    uint8_t                              matrix_coefficients;
    uint32_t                             num_units_in_tick;
    uint32_t                             time_scale;
    uint8_t                              max_num_reorder_frames;
    uint8_t                              max_dec_frame_buffering;
    uint8_t                              chroma_sample_loc_type_top_field;
    uint8_t                              chroma_sample_loc_type_bottom_field;
    uint32_t                             reserved1;
    const( StdVideoH264HrdParameters )*  pHrdParameters;
}

struct StdVideoH264SpsFlags {
}

struct StdVideoH264ScalingLists {
    uint16_t                                              scaling_list_present_mask;
    uint16_t                                              use_default_scaling_matrix_mask;
    uint8_t[ STD_VIDEO_H264_SCALING_LIST_4X4_NUM_LISTS ]  ScalingList4x4;
    uint8_t[ STD_VIDEO_H264_SCALING_LIST_8X8_NUM_LISTS ]  ScalingList8x8;
}

struct StdVideoH264SequenceParameterSet {
    StdVideoH264SpsFlags                           flags;
    StdVideoH264ProfileIdc                         profile_idc;
    StdVideoH264LevelIdc                           level_idc;
    StdVideoH264ChromaFormatIdc                    chroma_format_idc;
    uint8_t                                        seq_parameter_set_id;
    uint8_t                                        bit_depth_luma_minus8;
    uint8_t                                        bit_depth_chroma_minus8;
    uint8_t                                        log2_max_frame_num_minus4;
    StdVideoH264PocType                            pic_order_cnt_type;
    int32_t                                        offset_for_non_ref_pic;
    int32_t                                        offset_for_top_to_bottom_field;
    uint8_t                                        log2_max_pic_order_cnt_lsb_minus4;
    uint8_t                                        num_ref_frames_in_pic_order_cnt_cycle;
    uint8_t                                        max_num_ref_frames;
    uint8_t                                        reserved1;
    uint32_t                                       pic_width_in_mbs_minus1;
    uint32_t                                       pic_height_in_map_units_minus1;
    uint32_t                                       frame_crop_left_offset;
    uint32_t                                       frame_crop_right_offset;
    uint32_t                                       frame_crop_top_offset;
    uint32_t                                       frame_crop_bottom_offset;
    uint32_t                                       reserved2;
    const( int32_t )*                              pOffsetForRefFrame;
    const( StdVideoH264ScalingLists )*             pScalingLists;
    const( StdVideoH264SequenceParameterSetVui )*  pSequenceParameterSetVui;
}

struct StdVideoH264PpsFlags {
}

struct StdVideoH264PictureParameterSet {
    StdVideoH264PpsFlags                flags;
    uint8_t                             seq_parameter_set_id;
    uint8_t                             pic_parameter_set_id;
    uint8_t                             num_ref_idx_l0_default_active_minus1;
    uint8_t                             num_ref_idx_l1_default_active_minus1;
    StdVideoH264WeightedBipredIdc       weighted_bipred_idc;
    int8_t                              pic_init_qp_minus26;
    int8_t                              pic_init_qs_minus26;
    int8_t                              chroma_qp_index_offset;
    int8_t                              second_chroma_qp_index_offset;
    const( StdVideoH264ScalingLists )*  pScalingLists;
}


// - vulkan_video_codec_h264std_decode -
enum vulkan_video_codec_h264std_decode = 1;

enum VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0 = VK_MAKE_VIDEO_STD_VERSION( 1, 0, 0 );

enum STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_LIST_SIZE = 2;
enum VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_SPEC_VERSION = VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0;
enum const( char )* VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_EXTENSION_NAME = "VK_STD_vulkan_video_codec_h264_decode";

enum StdVideoDecodeH264FieldOrderCount {
    STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_TOP          = 0,
    STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_BOTTOM       = 1,
    STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_INVALID      = 0x7FFFFFFF,
    STD_VIDEO_DECODE_H2_64_FIELD_ORDER_COUNT_MAX_ENUM    = 0x7FFFFFFF
}

enum STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_TOP         = StdVideoDecodeH264FieldOrderCount.STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_TOP;
enum STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_BOTTOM      = StdVideoDecodeH264FieldOrderCount.STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_BOTTOM;
enum STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_INVALID     = StdVideoDecodeH264FieldOrderCount.STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_INVALID;
enum STD_VIDEO_DECODE_H2_64_FIELD_ORDER_COUNT_MAX_ENUM   = StdVideoDecodeH264FieldOrderCount.STD_VIDEO_DECODE_H2_64_FIELD_ORDER_COUNT_MAX_ENUM;

struct StdVideoDecodeH264PictureInfoFlags {
}

struct StdVideoDecodeH264PictureInfo {
    StdVideoDecodeH264PictureInfoFlags                            flags;
    uint8_t                                                       seq_parameter_set_id;
    uint8_t                                                       pic_parameter_set_id;
    uint8_t                                                       reserved1;
    uint8_t                                                       reserved2;
    uint16_t                                                      frame_num;
    uint16_t                                                      idr_pic_id;
    int32_t[ STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_LIST_SIZE ]  PicOrderCnt;
}

struct StdVideoDecodeH264ReferenceInfoFlags {
}

struct StdVideoDecodeH264ReferenceInfo {
    StdVideoDecodeH264ReferenceInfoFlags                          flags;
    uint16_t                                                      FrameNum;
    uint16_t                                                      reserved;
    int32_t[ STD_VIDEO_DECODE_H264_FIELD_ORDER_COUNT_LIST_SIZE ]  PicOrderCnt;
}


// - vulkan_video_codec_h264std_encode -
enum vulkan_video_codec_h264std_encode = 1;

// Vulkan 0.9 provisional Vulkan video H.264 encode std specification version number
enum VK_STD_VULKAN_VIDEO_CODEC_H264_ENCODE_API_VERSION_0_9_8 = VK_MAKE_VIDEO_STD_VERSION( 0, 9, 8 );

enum VK_STD_VULKAN_VIDEO_CODEC_H264_ENCODE_SPEC_VERSION = VK_STD_VULKAN_VIDEO_CODEC_H264_ENCODE_API_VERSION_0_9_8;
enum const( char )* VK_STD_VULKAN_VIDEO_CODEC_H264_ENCODE_EXTENSION_NAME = "VK_STD_vulkan_video_codec_h264_encode";

struct StdVideoEncodeH264WeightTableFlags {
    uint32_t  luma_weight_l0_flag;
    uint32_t  chroma_weight_l0_flag;
    uint32_t  luma_weight_l1_flag;
    uint32_t  chroma_weight_l1_flag;
}

struct StdVideoEncodeH264WeightTable {
    StdVideoEncodeH264WeightTableFlags         flags;
    uint8_t                                    luma_log2_weight_denom;
    uint8_t                                    chroma_log2_weight_denom;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  luma_weight_l0;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  luma_offset_l0;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  chroma_weight_l0;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  chroma_offset_l0;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  luma_weight_l1;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  luma_offset_l1;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  chroma_weight_l1;
    int8_t[ STD_VIDEO_H264_MAX_NUM_LIST_REF ]  chroma_offset_l1;
}

struct StdVideoEncodeH264SliceHeaderFlags {
}

struct StdVideoEncodeH264PictureInfoFlags {
}

struct StdVideoEncodeH264ReferenceInfoFlags {
}

struct StdVideoEncodeH264RefMgmtFlags {
}

struct StdVideoEncodeH264RefListModEntry {
    StdVideoH264ModificationOfPicNumsIdc  modification_of_pic_nums_idc;
    uint16_t                              abs_diff_pic_num_minus1;
    uint16_t                              long_term_pic_num;
}

struct StdVideoEncodeH264RefPicMarkingEntry {
    StdVideoH264MemMgmtControlOp  operation;
    uint16_t                      difference_of_pic_nums_minus1;
    uint16_t                      long_term_pic_num;
    uint16_t                      long_term_frame_idx;
    uint16_t                      max_long_term_frame_idx_plus1;
}

struct StdVideoEncodeH264RefMemMgmtCtrlOperations {
    StdVideoEncodeH264RefMgmtFlags                  flags;
    uint8_t                                         refList0ModOpCount;
    const( StdVideoEncodeH264RefListModEntry )*     pRefList0ModOperations;
    uint8_t                                         refList1ModOpCount;
    const( StdVideoEncodeH264RefListModEntry )*     pRefList1ModOperations;
    uint8_t                                         refPicMarkingOpCount;
    const( StdVideoEncodeH264RefPicMarkingEntry )*  pRefPicMarkingOperations;
}

struct StdVideoEncodeH264PictureInfo {
    StdVideoEncodeH264PictureInfoFlags  flags;
    uint8_t                             seq_parameter_set_id;
    uint8_t                             pic_parameter_set_id;
    StdVideoH264PictureType             pictureType;
    uint32_t                            frame_num;
    int32_t                             PicOrderCnt;
}

struct StdVideoEncodeH264ReferenceInfo {
    StdVideoEncodeH264ReferenceInfoFlags  flags;
    uint32_t                              FrameNum;
    int32_t                               PicOrderCnt;
    uint16_t                              long_term_pic_num;
    uint16_t                              long_term_frame_idx;
}

struct StdVideoEncodeH264SliceHeader {
    StdVideoEncodeH264SliceHeaderFlags       flags;
    uint32_t                                 first_mb_in_slice;
    StdVideoH264SliceType                    slice_type;
    uint16_t                                 idr_pic_id;
    uint8_t                                  num_ref_idx_l0_active_minus1;
    uint8_t                                  num_ref_idx_l1_active_minus1;
    StdVideoH264CabacInitIdc                 cabac_init_idc;
    StdVideoH264DisableDeblockingFilterIdc   disable_deblocking_filter_idc;
    int8_t                                   slice_alpha_c0_offset_div2;
    int8_t                                   slice_beta_offset_div2;
    const( StdVideoEncodeH264WeightTable )*  pWeightTable;
}


// - vulkan_video_codec_h265std -
enum vulkan_video_codec_h265std = 1;

enum STD_VIDEO_H265_SUBLAYERS_LIST_SIZE = 7;
enum STD_VIDEO_H265_CPB_CNT_LIST_SIZE = 32;
enum STD_VIDEO_H265_SCALING_LIST_4X4_NUM_LISTS = 6;
enum STD_VIDEO_H265_SCALING_LIST_4X4_NUM_ELEMENTS = 16;
enum STD_VIDEO_H265_SCALING_LIST_8X8_NUM_LISTS = 6;
enum STD_VIDEO_H265_SCALING_LIST_8X8_NUM_ELEMENTS = 64;
enum STD_VIDEO_H265_SCALING_LIST_16X16_NUM_LISTS = 6;
enum STD_VIDEO_H265_SCALING_LIST_16X16_NUM_ELEMENTS = 64;
enum STD_VIDEO_H265_SCALING_LIST_32X32_NUM_LISTS = 2;
enum STD_VIDEO_H265_SCALING_LIST_32X32_NUM_ELEMENTS = 64;
enum STD_VIDEO_H265_PREDICTOR_PALETTE_COMPONENTS_LIST_SIZE = 3;
enum STD_VIDEO_H265_PREDICTOR_PALETTE_COMP_ENTRIES_LIST_SIZE = 128;
enum STD_VIDEO_H265_MAX_DPB_SIZE = 16;
enum STD_VIDEO_H265_MAX_LONG_TERM_REF_PICS_SPS = 32;
enum STD_VIDEO_H265_CHROMA_QP_OFFSET_LIST_SIZE = 6;
enum STD_VIDEO_H265_CHROMA_QP_OFFSET_TILE_COLS_LIST_SIZE = 19;
enum STD_VIDEO_H265_CHROMA_QP_OFFSET_TILE_ROWS_LIST_SIZE = 21;
enum STD_VIDEO_H265_MAX_NUM_LIST_REF = 15;
enum STD_VIDEO_H265_MAX_CHROMA_PLANES = 2;
enum STD_VIDEO_H265_MAX_SHORT_TERM_REF_PIC_SETS = 64;
enum STD_VIDEO_H265_MAX_LONG_TERM_PICS = 16;
enum STD_VIDEO_H265_MAX_DELTA_POC = 48;

enum StdVideoH265ChromaFormatIdc {
    STD_VIDEO_H265_CHROMA_FORMAT_IDC_MONOCHROME  = 0,
    STD_VIDEO_H265_CHROMA_FORMAT_IDC_420         = 1,
    STD_VIDEO_H265_CHROMA_FORMAT_IDC_422         = 2,
    STD_VIDEO_H265_CHROMA_FORMAT_IDC_444         = 3,
    STD_VIDEO_H265_CHROMA_FORMAT_IDC_INVALID     = 0x7FFFFFFF,
    STD_VIDEO_H2_65_CHROMA_FORMAT_IDC_MAX_ENUM   = 0x7FFFFFFF
}

enum STD_VIDEO_H265_CHROMA_FORMAT_IDC_MONOCHROME = StdVideoH265ChromaFormatIdc.STD_VIDEO_H265_CHROMA_FORMAT_IDC_MONOCHROME;
enum STD_VIDEO_H265_CHROMA_FORMAT_IDC_420        = StdVideoH265ChromaFormatIdc.STD_VIDEO_H265_CHROMA_FORMAT_IDC_420;
enum STD_VIDEO_H265_CHROMA_FORMAT_IDC_422        = StdVideoH265ChromaFormatIdc.STD_VIDEO_H265_CHROMA_FORMAT_IDC_422;
enum STD_VIDEO_H265_CHROMA_FORMAT_IDC_444        = StdVideoH265ChromaFormatIdc.STD_VIDEO_H265_CHROMA_FORMAT_IDC_444;
enum STD_VIDEO_H265_CHROMA_FORMAT_IDC_INVALID    = StdVideoH265ChromaFormatIdc.STD_VIDEO_H265_CHROMA_FORMAT_IDC_INVALID;
enum STD_VIDEO_H2_65_CHROMA_FORMAT_IDC_MAX_ENUM  = StdVideoH265ChromaFormatIdc.STD_VIDEO_H2_65_CHROMA_FORMAT_IDC_MAX_ENUM;

enum StdVideoH265ProfileIdc {
    STD_VIDEO_H265_PROFILE_IDC_MAIN                      = 1,
    STD_VIDEO_H265_PROFILE_IDC_MAIN_10                   = 2,
    STD_VIDEO_H265_PROFILE_IDC_MAIN_STILL_PICTURE        = 3,
    STD_VIDEO_H265_PROFILE_IDC_FORMAT_RANGE_EXTENSIONS   = 4,
    STD_VIDEO_H265_PROFILE_IDC_SCC_EXTENSIONS            = 9,
    STD_VIDEO_H265_PROFILE_IDC_INVALID                   = 0x7FFFFFFF,
    STD_VIDEO_H2_65_PROFILE_IDC_MAX_ENUM                 = 0x7FFFFFFF
}

enum STD_VIDEO_H265_PROFILE_IDC_MAIN                     = StdVideoH265ProfileIdc.STD_VIDEO_H265_PROFILE_IDC_MAIN;
enum STD_VIDEO_H265_PROFILE_IDC_MAIN_10                  = StdVideoH265ProfileIdc.STD_VIDEO_H265_PROFILE_IDC_MAIN_10;
enum STD_VIDEO_H265_PROFILE_IDC_MAIN_STILL_PICTURE       = StdVideoH265ProfileIdc.STD_VIDEO_H265_PROFILE_IDC_MAIN_STILL_PICTURE;
enum STD_VIDEO_H265_PROFILE_IDC_FORMAT_RANGE_EXTENSIONS  = StdVideoH265ProfileIdc.STD_VIDEO_H265_PROFILE_IDC_FORMAT_RANGE_EXTENSIONS;
enum STD_VIDEO_H265_PROFILE_IDC_SCC_EXTENSIONS           = StdVideoH265ProfileIdc.STD_VIDEO_H265_PROFILE_IDC_SCC_EXTENSIONS;
enum STD_VIDEO_H265_PROFILE_IDC_INVALID                  = StdVideoH265ProfileIdc.STD_VIDEO_H265_PROFILE_IDC_INVALID;
enum STD_VIDEO_H2_65_PROFILE_IDC_MAX_ENUM                = StdVideoH265ProfileIdc.STD_VIDEO_H2_65_PROFILE_IDC_MAX_ENUM;

enum StdVideoH265LevelIdc {
    STD_VIDEO_H265_LEVEL_IDC_1_0         = 0,
    STD_VIDEO_H265_LEVEL_IDC_2_0         = 1,
    STD_VIDEO_H265_LEVEL_IDC_2_1         = 2,
    STD_VIDEO_H265_LEVEL_IDC_3_0         = 3,
    STD_VIDEO_H265_LEVEL_IDC_3_1         = 4,
    STD_VIDEO_H265_LEVEL_IDC_4_0         = 5,
    STD_VIDEO_H265_LEVEL_IDC_4_1         = 6,
    STD_VIDEO_H265_LEVEL_IDC_5_0         = 7,
    STD_VIDEO_H265_LEVEL_IDC_5_1         = 8,
    STD_VIDEO_H265_LEVEL_IDC_5_2         = 9,
    STD_VIDEO_H265_LEVEL_IDC_6_0         = 10,
    STD_VIDEO_H265_LEVEL_IDC_6_1         = 11,
    STD_VIDEO_H265_LEVEL_IDC_6_2         = 12,
    STD_VIDEO_H265_LEVEL_IDC_INVALID     = 0x7FFFFFFF,
    STD_VIDEO_H2_65_LEVEL_IDC_MAX_ENUM   = 0x7FFFFFFF
}

enum STD_VIDEO_H265_LEVEL_IDC_1_0        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_1_0;
enum STD_VIDEO_H265_LEVEL_IDC_2_0        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_2_0;
enum STD_VIDEO_H265_LEVEL_IDC_2_1        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_2_1;
enum STD_VIDEO_H265_LEVEL_IDC_3_0        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_3_0;
enum STD_VIDEO_H265_LEVEL_IDC_3_1        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_3_1;
enum STD_VIDEO_H265_LEVEL_IDC_4_0        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_4_0;
enum STD_VIDEO_H265_LEVEL_IDC_4_1        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_4_1;
enum STD_VIDEO_H265_LEVEL_IDC_5_0        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_5_0;
enum STD_VIDEO_H265_LEVEL_IDC_5_1        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_5_1;
enum STD_VIDEO_H265_LEVEL_IDC_5_2        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_5_2;
enum STD_VIDEO_H265_LEVEL_IDC_6_0        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_6_0;
enum STD_VIDEO_H265_LEVEL_IDC_6_1        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_6_1;
enum STD_VIDEO_H265_LEVEL_IDC_6_2        = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_6_2;
enum STD_VIDEO_H265_LEVEL_IDC_INVALID    = StdVideoH265LevelIdc.STD_VIDEO_H265_LEVEL_IDC_INVALID;
enum STD_VIDEO_H2_65_LEVEL_IDC_MAX_ENUM  = StdVideoH265LevelIdc.STD_VIDEO_H2_65_LEVEL_IDC_MAX_ENUM;

enum StdVideoH265SliceType {
    STD_VIDEO_H265_SLICE_TYPE_B          = 0,
    STD_VIDEO_H265_SLICE_TYPE_P          = 1,
    STD_VIDEO_H265_SLICE_TYPE_I          = 2,
    STD_VIDEO_H265_SLICE_TYPE_INVALID    = 0x7FFFFFFF,
    STD_VIDEO_H2_65_SLICE_TYPE_MAX_ENUM  = 0x7FFFFFFF
}

enum STD_VIDEO_H265_SLICE_TYPE_B         = StdVideoH265SliceType.STD_VIDEO_H265_SLICE_TYPE_B;
enum STD_VIDEO_H265_SLICE_TYPE_P         = StdVideoH265SliceType.STD_VIDEO_H265_SLICE_TYPE_P;
enum STD_VIDEO_H265_SLICE_TYPE_I         = StdVideoH265SliceType.STD_VIDEO_H265_SLICE_TYPE_I;
enum STD_VIDEO_H265_SLICE_TYPE_INVALID   = StdVideoH265SliceType.STD_VIDEO_H265_SLICE_TYPE_INVALID;
enum STD_VIDEO_H2_65_SLICE_TYPE_MAX_ENUM = StdVideoH265SliceType.STD_VIDEO_H2_65_SLICE_TYPE_MAX_ENUM;

enum StdVideoH265PictureType {
    STD_VIDEO_H265_PICTURE_TYPE_P        = 0,
    STD_VIDEO_H265_PICTURE_TYPE_B        = 1,
    STD_VIDEO_H265_PICTURE_TYPE_I        = 2,
    STD_VIDEO_H265_PICTURE_TYPE_IDR      = 3,
    STD_VIDEO_H265_PICTURE_TYPE_INVALID  = 0x7FFFFFFF,
    STD_VIDEO_H2_65_PICTURE_TYPE_MAX_ENUM = 0x7FFFFFFF
}

enum STD_VIDEO_H265_PICTURE_TYPE_P       = StdVideoH265PictureType.STD_VIDEO_H265_PICTURE_TYPE_P;
enum STD_VIDEO_H265_PICTURE_TYPE_B       = StdVideoH265PictureType.STD_VIDEO_H265_PICTURE_TYPE_B;
enum STD_VIDEO_H265_PICTURE_TYPE_I       = StdVideoH265PictureType.STD_VIDEO_H265_PICTURE_TYPE_I;
enum STD_VIDEO_H265_PICTURE_TYPE_IDR     = StdVideoH265PictureType.STD_VIDEO_H265_PICTURE_TYPE_IDR;
enum STD_VIDEO_H265_PICTURE_TYPE_INVALID = StdVideoH265PictureType.STD_VIDEO_H265_PICTURE_TYPE_INVALID;
enum STD_VIDEO_H2_65_PICTURE_TYPE_MAX_ENUM = StdVideoH265PictureType.STD_VIDEO_H2_65_PICTURE_TYPE_MAX_ENUM;

enum StdVideoH265AspectRatioIdc {
    STD_VIDEO_H265_ASPECT_RATIO_IDC_UNSPECIFIED          = 0,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_SQUARE               = 1,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_12_11                = 2,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_10_11                = 3,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_16_11                = 4,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_40_33                = 5,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_24_11                = 6,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_20_11                = 7,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_32_11                = 8,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_80_33                = 9,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_18_11                = 10,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_15_11                = 11,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_64_33                = 12,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_160_99               = 13,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_4_3                  = 14,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_3_2                  = 15,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_2_1                  = 16,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_EXTENDED_SAR         = 255,
    STD_VIDEO_H265_ASPECT_RATIO_IDC_INVALID              = 0x7FFFFFFF,
    STD_VIDEO_H2_65_ASPECT_RATIO_IDC_MAX_ENUM            = 0x7FFFFFFF
}

enum STD_VIDEO_H265_ASPECT_RATIO_IDC_UNSPECIFIED         = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_UNSPECIFIED;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_SQUARE              = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_SQUARE;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_12_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_12_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_10_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_10_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_16_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_16_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_40_33               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_40_33;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_24_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_24_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_20_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_20_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_32_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_32_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_80_33               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_80_33;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_18_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_18_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_15_11               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_15_11;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_64_33               = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_64_33;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_160_99              = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_160_99;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_4_3                 = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_4_3;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_3_2                 = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_3_2;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_2_1                 = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_2_1;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_EXTENDED_SAR        = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_EXTENDED_SAR;
enum STD_VIDEO_H265_ASPECT_RATIO_IDC_INVALID             = StdVideoH265AspectRatioIdc.STD_VIDEO_H265_ASPECT_RATIO_IDC_INVALID;
enum STD_VIDEO_H2_65_ASPECT_RATIO_IDC_MAX_ENUM           = StdVideoH265AspectRatioIdc.STD_VIDEO_H2_65_ASPECT_RATIO_IDC_MAX_ENUM;

struct StdVideoH265DecPicBufMgr {
    uint32_t[ STD_VIDEO_H265_SUBLAYERS_LIST_SIZE ]  max_latency_increase_plus1;
    uint8_t[ STD_VIDEO_H265_SUBLAYERS_LIST_SIZE ]   max_dec_pic_buffering_minus1;
    uint8_t[ STD_VIDEO_H265_SUBLAYERS_LIST_SIZE ]   max_num_reorder_pics;
}

struct StdVideoH265SubLayerHrdParameters {
    uint32_t[ STD_VIDEO_H265_CPB_CNT_LIST_SIZE ]  bit_rate_value_minus1;
    uint32_t[ STD_VIDEO_H265_CPB_CNT_LIST_SIZE ]  cpb_size_value_minus1;
    uint32_t[ STD_VIDEO_H265_CPB_CNT_LIST_SIZE ]  cpb_size_du_value_minus1;
    uint32_t[ STD_VIDEO_H265_CPB_CNT_LIST_SIZE ]  bit_rate_du_value_minus1;
    uint32_t                                      cbr_flag;
}

struct StdVideoH265HrdFlags {
}

struct StdVideoH265HrdParameters {
    StdVideoH265HrdFlags                            flags;
    uint8_t                                         tick_divisor_minus2;
    uint8_t                                         du_cpb_removal_delay_increment_length_minus1;
    uint8_t                                         dpb_output_delay_du_length_minus1;
    uint8_t                                         bit_rate_scale;
    uint8_t                                         cpb_size_scale;
    uint8_t                                         cpb_size_du_scale;
    uint8_t                                         initial_cpb_removal_delay_length_minus1;
    uint8_t                                         au_cpb_removal_delay_length_minus1;
    uint8_t                                         dpb_output_delay_length_minus1;
    uint8_t[ STD_VIDEO_H265_SUBLAYERS_LIST_SIZE ]   cpb_cnt_minus1;
    uint16_t[ STD_VIDEO_H265_SUBLAYERS_LIST_SIZE ]  elemental_duration_in_tc_minus1;
    uint16_t[3]                                     reserved;
    const( StdVideoH265SubLayerHrdParameters )*     pSubLayerHrdParametersNal;
    const( StdVideoH265SubLayerHrdParameters )*     pSubLayerHrdParametersVcl;
}

struct StdVideoH265VpsFlags {
}

struct StdVideoH265ProfileTierLevelFlags {
}

struct StdVideoH265ProfileTierLevel {
    StdVideoH265ProfileTierLevelFlags  flags;
    StdVideoH265ProfileIdc             general_profile_idc;
    StdVideoH265LevelIdc               general_level_idc;
}

struct StdVideoH265VideoParameterSet {
    StdVideoH265VpsFlags                    flags;
    uint8_t                                 vps_video_parameter_set_id;
    uint8_t                                 vps_max_sub_layers_minus1;
    uint8_t                                 reserved1;
    uint8_t                                 reserved2;
    uint32_t                                vps_num_units_in_tick;
    uint32_t                                vps_time_scale;
    uint32_t                                vps_num_ticks_poc_diff_one_minus1;
    uint32_t                                reserved3;
    const( StdVideoH265DecPicBufMgr )*      pDecPicBufMgr;
    const( StdVideoH265HrdParameters )*     pHrdParameters;
    const( StdVideoH265ProfileTierLevel )*  pProfileTierLevel;
}

struct StdVideoH265ScalingLists {
    uint8_t[ STD_VIDEO_H265_SCALING_LIST_4X4_NUM_LISTS ]    ScalingList4x4;
    uint8_t[ STD_VIDEO_H265_SCALING_LIST_8X8_NUM_LISTS ]    ScalingList8x8;
    uint8_t[ STD_VIDEO_H265_SCALING_LIST_16X16_NUM_LISTS ]  ScalingList16x16;
    uint8_t[ STD_VIDEO_H265_SCALING_LIST_32X32_NUM_LISTS ]  ScalingList32x32;
    uint8_t[ STD_VIDEO_H265_SCALING_LIST_16X16_NUM_LISTS ]  ScalingListDCCoef16x16;
    uint8_t[ STD_VIDEO_H265_SCALING_LIST_32X32_NUM_LISTS ]  ScalingListDCCoef32x32;
}

struct StdVideoH265SpsVuiFlags {
}

struct StdVideoH265SequenceParameterSetVui {
    StdVideoH265SpsVuiFlags              flags;
    StdVideoH265AspectRatioIdc           aspect_ratio_idc;
    uint16_t                             sar_width;
    uint16_t                             sar_height;
    uint8_t                              video_format;
    uint8_t                              colour_primaries;
    uint8_t                              transfer_characteristics;
    uint8_t                              matrix_coeffs;
    uint8_t                              chroma_sample_loc_type_top_field;
    uint8_t                              chroma_sample_loc_type_bottom_field;
    uint8_t                              reserved1;
    uint8_t                              reserved2;
    uint16_t                             def_disp_win_left_offset;
    uint16_t                             def_disp_win_right_offset;
    uint16_t                             def_disp_win_top_offset;
    uint16_t                             def_disp_win_bottom_offset;
    uint32_t                             vui_num_units_in_tick;
    uint32_t                             vui_time_scale;
    uint32_t                             vui_num_ticks_poc_diff_one_minus1;
    uint16_t                             min_spatial_segmentation_idc;
    uint16_t                             reserved3;
    uint8_t                              max_bytes_per_pic_denom;
    uint8_t                              max_bits_per_min_cu_denom;
    uint8_t                              log2_max_mv_length_horizontal;
    uint8_t                              log2_max_mv_length_vertical;
    const( StdVideoH265HrdParameters )*  pHrdParameters;
}

struct StdVideoH265PredictorPaletteEntries {
    uint16_t[ STD_VIDEO_H265_PREDICTOR_PALETTE_COMPONENTS_LIST_SIZE ]  PredictorPaletteEntries;
}

struct StdVideoH265SpsFlags {
}

struct StdVideoH265ShortTermRefPicSetFlags {
}

struct StdVideoH265ShortTermRefPicSet {
    StdVideoH265ShortTermRefPicSetFlags      flags;
    uint32_t                                 delta_idx_minus1;
    uint16_t                                 use_delta_flag;
    uint16_t                                 abs_delta_rps_minus1;
    uint16_t                                 used_by_curr_pic_flag;
    uint16_t                                 used_by_curr_pic_s0_flag;
    uint16_t                                 used_by_curr_pic_s1_flag;
    uint16_t                                 reserved1;
    uint8_t                                  reserved2;
    uint8_t                                  reserved3;
    uint8_t                                  num_negative_pics;
    uint8_t                                  num_positive_pics;
    uint16_t[ STD_VIDEO_H265_MAX_DPB_SIZE ]  delta_poc_s0_minus1;
    uint16_t[ STD_VIDEO_H265_MAX_DPB_SIZE ]  delta_poc_s1_minus1;
}

struct StdVideoH265LongTermRefPicsSps {
    uint32_t                                               used_by_curr_pic_lt_sps_flag;
    uint32_t[ STD_VIDEO_H265_MAX_LONG_TERM_REF_PICS_SPS ]  lt_ref_pic_poc_lsb_sps;
}

struct StdVideoH265SequenceParameterSet {
    StdVideoH265SpsFlags                           flags;
    StdVideoH265ChromaFormatIdc                    chroma_format_idc;
    uint32_t                                       pic_width_in_luma_samples;
    uint32_t                                       pic_height_in_luma_samples;
    uint8_t                                        sps_video_parameter_set_id;
    uint8_t                                        sps_max_sub_layers_minus1;
    uint8_t                                        sps_seq_parameter_set_id;
    uint8_t                                        bit_depth_luma_minus8;
    uint8_t                                        bit_depth_chroma_minus8;
    uint8_t                                        log2_max_pic_order_cnt_lsb_minus4;
    uint8_t                                        log2_min_luma_coding_block_size_minus3;
    uint8_t                                        log2_diff_max_min_luma_coding_block_size;
    uint8_t                                        log2_min_luma_transform_block_size_minus2;
    uint8_t                                        log2_diff_max_min_luma_transform_block_size;
    uint8_t                                        max_transform_hierarchy_depth_inter;
    uint8_t                                        max_transform_hierarchy_depth_intra;
    uint8_t                                        num_short_term_ref_pic_sets;
    uint8_t                                        num_long_term_ref_pics_sps;
    uint8_t                                        pcm_sample_bit_depth_luma_minus1;
    uint8_t                                        pcm_sample_bit_depth_chroma_minus1;
    uint8_t                                        log2_min_pcm_luma_coding_block_size_minus3;
    uint8_t                                        log2_diff_max_min_pcm_luma_coding_block_size;
    uint8_t                                        reserved1;
    uint8_t                                        reserved2;
    uint8_t                                        palette_max_size;
    uint8_t                                        delta_palette_max_predictor_size;
    uint8_t                                        motion_vector_resolution_control_idc;
    uint8_t                                        sps_num_palette_predictor_initializers_minus1;
    uint32_t                                       conf_win_left_offset;
    uint32_t                                       conf_win_right_offset;
    uint32_t                                       conf_win_top_offset;
    uint32_t                                       conf_win_bottom_offset;
    const( StdVideoH265ProfileTierLevel )*         pProfileTierLevel;
    const( StdVideoH265DecPicBufMgr )*             pDecPicBufMgr;
    const( StdVideoH265ScalingLists )*             pScalingLists;
    const( StdVideoH265ShortTermRefPicSet )*       pShortTermRefPicSet;
    const( StdVideoH265LongTermRefPicsSps )*       pLongTermRefPicsSps;
    const( StdVideoH265SequenceParameterSetVui )*  pSequenceParameterSetVui;
    const( StdVideoH265PredictorPaletteEntries )*  pPredictorPaletteEntries;
}

struct StdVideoH265PpsFlags {
}

struct StdVideoH265PictureParameterSet {
    StdVideoH265PpsFlags                                             flags;
    uint8_t                                                          pps_pic_parameter_set_id;
    uint8_t                                                          pps_seq_parameter_set_id;
    uint8_t                                                          sps_video_parameter_set_id;
    uint8_t                                                          num_extra_slice_header_bits;
    uint8_t                                                          num_ref_idx_l0_default_active_minus1;
    uint8_t                                                          num_ref_idx_l1_default_active_minus1;
    int8_t                                                           init_qp_minus26;
    uint8_t                                                          diff_cu_qp_delta_depth;
    int8_t                                                           pps_cb_qp_offset;
    int8_t                                                           pps_cr_qp_offset;
    int8_t                                                           pps_beta_offset_div2;
    int8_t                                                           pps_tc_offset_div2;
    uint8_t                                                          log2_parallel_merge_level_minus2;
    uint8_t                                                          log2_max_transform_skip_block_size_minus2;
    uint8_t                                                          diff_cu_chroma_qp_offset_depth;
    uint8_t                                                          chroma_qp_offset_list_len_minus1;
    int8_t[ STD_VIDEO_H265_CHROMA_QP_OFFSET_LIST_SIZE ]              cb_qp_offset_list;
    int8_t[ STD_VIDEO_H265_CHROMA_QP_OFFSET_LIST_SIZE ]              cr_qp_offset_list;
    uint8_t                                                          log2_sao_offset_scale_luma;
    uint8_t                                                          log2_sao_offset_scale_chroma;
    int8_t                                                           pps_act_y_qp_offset_plus5;
    int8_t                                                           pps_act_cb_qp_offset_plus5;
    int8_t                                                           pps_act_cr_qp_offset_plus3;
    uint8_t                                                          pps_num_palette_predictor_initializers;
    uint8_t                                                          luma_bit_depth_entry_minus8;
    uint8_t                                                          chroma_bit_depth_entry_minus8;
    uint8_t                                                          num_tile_columns_minus1;
    uint8_t                                                          num_tile_rows_minus1;
    uint8_t                                                          reserved1;
    uint8_t                                                          reserved2;
    uint16_t[ STD_VIDEO_H265_CHROMA_QP_OFFSET_TILE_COLS_LIST_SIZE ]  column_width_minus1;
    uint16_t[ STD_VIDEO_H265_CHROMA_QP_OFFSET_TILE_ROWS_LIST_SIZE ]  row_height_minus1;
    uint32_t                                                         reserved3;
    const( StdVideoH265ScalingLists )*                               pScalingLists;
    const( StdVideoH265PredictorPaletteEntries )*                    pPredictorPaletteEntries;
}


// - vulkan_video_codec_h265std_decode -
enum vulkan_video_codec_h265std_decode = 1;

enum VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0 = VK_MAKE_VIDEO_STD_VERSION( 1, 0, 0 );

enum STD_VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE = 8;
enum VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_SPEC_VERSION = VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0;
enum const( char )* VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_EXTENSION_NAME = "VK_STD_vulkan_video_codec_h265_decode";

struct StdVideoDecodeH265PictureInfoFlags {
}

struct StdVideoDecodeH265PictureInfo {
    StdVideoDecodeH265PictureInfoFlags                      flags;
    uint8_t                                                 sps_video_parameter_set_id;
    uint8_t                                                 pps_seq_parameter_set_id;
    uint8_t                                                 pps_pic_parameter_set_id;
    uint8_t                                                 NumDeltaPocsOfRefRpsIdx;
    int32_t                                                 PicOrderCntVal;
    uint16_t                                                NumBitsForSTRefPicSetInSlice;
    uint16_t                                                reserved;
    uint8_t[ STD_VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE ]  RefPicSetStCurrBefore;
    uint8_t[ STD_VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE ]  RefPicSetStCurrAfter;
    uint8_t[ STD_VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE ]  RefPicSetLtCurr;
}

struct StdVideoDecodeH265ReferenceInfoFlags {
}

struct StdVideoDecodeH265ReferenceInfo {
    StdVideoDecodeH265ReferenceInfoFlags  flags;
    int32_t                               PicOrderCntVal;
}


// - vulkan_video_codec_h265std_encode -
enum vulkan_video_codec_h265std_encode = 1;

// Vulkan 0.9 provisional Vulkan video H.265 encode std specification version number
enum VK_STD_VULKAN_VIDEO_CODEC_H265_ENCODE_API_VERSION_0_9_9 = VK_MAKE_VIDEO_STD_VERSION( 0, 9, 9 );

enum VK_STD_VULKAN_VIDEO_CODEC_H265_ENCODE_SPEC_VERSION = VK_STD_VULKAN_VIDEO_CODEC_H265_ENCODE_API_VERSION_0_9_9;
enum const( char )* VK_STD_VULKAN_VIDEO_CODEC_H265_ENCODE_EXTENSION_NAME = "VK_STD_vulkan_video_codec_h265_encode";

struct StdVideoEncodeH265WeightTableFlags {
    uint16_t  luma_weight_l0_flag;
    uint16_t  chroma_weight_l0_flag;
    uint16_t  luma_weight_l1_flag;
    uint16_t  chroma_weight_l1_flag;
}

struct StdVideoEncodeH265WeightTable {
    StdVideoEncodeH265WeightTableFlags         flags;
    uint8_t                                    luma_log2_weight_denom;
    int8_t                                     delta_chroma_log2_weight_denom;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  delta_luma_weight_l0;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  luma_offset_l0;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  delta_chroma_weight_l0;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  delta_chroma_offset_l0;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  delta_luma_weight_l1;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  luma_offset_l1;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  delta_chroma_weight_l1;
    int8_t[ STD_VIDEO_H265_MAX_NUM_LIST_REF ]  delta_chroma_offset_l1;
}

struct StdVideoEncodeH265SliceSegmentHeaderFlags {
}

struct StdVideoEncodeH265SliceSegmentLongTermRefPics {
    uint8_t                                               num_long_term_sps;
    uint8_t                                               num_long_term_pics;
    uint8_t[ STD_VIDEO_H265_MAX_LONG_TERM_REF_PICS_SPS ]  lt_idx_sps;
    uint8_t[ STD_VIDEO_H265_MAX_LONG_TERM_PICS ]          poc_lsb_lt;
    uint16_t                                              used_by_curr_pic_lt_flag;
    uint8_t[ STD_VIDEO_H265_MAX_DELTA_POC ]               delta_poc_msb_present_flag;
    uint8_t[ STD_VIDEO_H265_MAX_DELTA_POC ]               delta_poc_msb_cycle_lt;
}

struct StdVideoEncodeH265SliceSegmentHeader {
    StdVideoEncodeH265SliceSegmentHeaderFlags                flags;
    StdVideoH265SliceType                                    slice_type;
    uint32_t                                                 slice_segment_address;
    uint8_t                                                  short_term_ref_pic_set_idx;
    uint8_t                                                  collocated_ref_idx;
    uint8_t                                                  num_ref_idx_l0_active_minus1;
    uint8_t                                                  num_ref_idx_l1_active_minus1;
    uint8_t                                                  MaxNumMergeCand;
    int8_t                                                   slice_cb_qp_offset;
    int8_t                                                   slice_cr_qp_offset;
    int8_t                                                   slice_beta_offset_div2;
    int8_t                                                   slice_tc_offset_div2;
    int8_t                                                   slice_act_y_qp_offset;
    int8_t                                                   slice_act_cb_qp_offset;
    int8_t                                                   slice_act_cr_qp_offset;
    const( StdVideoH265ShortTermRefPicSet )*                 pShortTermRefPicSet;
    const( StdVideoEncodeH265SliceSegmentLongTermRefPics )*  pLongTermRefPics;
    const( StdVideoEncodeH265WeightTable )*                  pWeightTable;
}

struct StdVideoEncodeH265ReferenceModificationFlags {
}

struct StdVideoEncodeH265ReferenceModifications {
    StdVideoEncodeH265ReferenceModificationFlags  flags;
    uint8_t                                       referenceList0ModificationsCount;
    const( uint8_t )*                             pReferenceList0Modifications;
    uint8_t                                       referenceList1ModificationsCount;
    const( uint8_t )*                             pReferenceList1Modifications;
}

struct StdVideoEncodeH265PictureInfoFlags {
}

struct StdVideoEncodeH265PictureInfo {
    StdVideoEncodeH265PictureInfoFlags  flags;
    StdVideoH265PictureType             PictureType;
    uint8_t                             sps_video_parameter_set_id;
    uint8_t                             pps_seq_parameter_set_id;
    uint8_t                             pps_pic_parameter_set_id;
    int32_t                             PicOrderCntVal;
    uint8_t                             TemporalId;
}

struct StdVideoEncodeH265ReferenceInfoFlags {
}

struct StdVideoEncodeH265ReferenceInfo {
    StdVideoEncodeH265ReferenceInfoFlags  flags;
    int32_t                               PicOrderCntVal;
    uint8_t                               TemporalId;
}



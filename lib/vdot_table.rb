module VdotTable
  # Jack Daniels' Running Formula ベースの VDOT 定数テーブル
  # VDOT 53-66 は run_app の実データ、他は同データを錨点に補間
  # ペースはすべて秒/km、full_marathon_time は秒
  TABLE = [
    { vdot: 30, full_marathon_time: 16000, easy_pace: 472, marathon_pace: 380, threshold_pace: 360, cv_pace: 346, interval_pace: 331, repetition_pace: 307 },
    { vdot: 31, full_marathon_time: 15776, easy_pace: 466, marathon_pace: 374, threshold_pace: 355, cv_pace: 341, interval_pace: 327, repetition_pace: 303 },
    { vdot: 32, full_marathon_time: 15553, easy_pace: 459, marathon_pace: 369, threshold_pace: 350, cv_pace: 336, interval_pace: 322, repetition_pace: 298 },
    { vdot: 33, full_marathon_time: 15329, easy_pace: 453, marathon_pace: 364, threshold_pace: 345, cv_pace: 331, interval_pace: 318, repetition_pace: 294 },
    { vdot: 34, full_marathon_time: 15106, easy_pace: 446, marathon_pace: 358, threshold_pace: 340, cv_pace: 326, interval_pace: 313, repetition_pace: 290 },
    { vdot: 35, full_marathon_time: 14882, easy_pace: 440, marathon_pace: 353, threshold_pace: 335, cv_pace: 321, interval_pace: 308, repetition_pace: 286 },
    { vdot: 36, full_marathon_time: 14659, easy_pace: 433, marathon_pace: 348, threshold_pace: 330, cv_pace: 317, interval_pace: 304, repetition_pace: 281 },
    { vdot: 37, full_marathon_time: 14435, easy_pace: 426, marathon_pace: 342, threshold_pace: 325, cv_pace: 312, interval_pace: 299, repetition_pace: 277 },
    { vdot: 38, full_marathon_time: 14212, easy_pace: 420, marathon_pace: 337, threshold_pace: 320, cv_pace: 307, interval_pace: 294, repetition_pace: 273 },
    { vdot: 39, full_marathon_time: 13988, easy_pace: 413, marathon_pace: 332, threshold_pace: 315, cv_pace: 302, interval_pace: 290, repetition_pace: 268 },
    { vdot: 40, full_marathon_time: 13765, easy_pace: 406, marathon_pace: 327, threshold_pace: 310, cv_pace: 298, interval_pace: 285, repetition_pace: 264 },
    { vdot: 41, full_marathon_time: 13541, easy_pace: 400, marathon_pace: 321, threshold_pace: 305, cv_pace: 293, interval_pace: 281, repetition_pace: 260 },
    { vdot: 42, full_marathon_time: 13318, easy_pace: 393, marathon_pace: 316, threshold_pace: 300, cv_pace: 288, interval_pace: 276, repetition_pace: 256 },
    { vdot: 43, full_marathon_time: 13094, easy_pace: 387, marathon_pace: 311, threshold_pace: 295, cv_pace: 283, interval_pace: 271, repetition_pace: 251 },
    { vdot: 44, full_marathon_time: 12871, easy_pace: 380, marathon_pace: 305, threshold_pace: 290, cv_pace: 278, interval_pace: 267, repetition_pace: 247 },
    { vdot: 45, full_marathon_time: 12647, easy_pace: 373, marathon_pace: 300, threshold_pace: 285, cv_pace: 273, interval_pace: 262, repetition_pace: 243 },
    { vdot: 46, full_marathon_time: 12424, easy_pace: 367, marathon_pace: 295, threshold_pace: 280, cv_pace: 268, interval_pace: 257, repetition_pace: 238 },
    { vdot: 47, full_marathon_time: 12200, easy_pace: 360, marathon_pace: 289, threshold_pace: 275, cv_pace: 264, interval_pace: 253, repetition_pace: 234 },
    { vdot: 48, full_marathon_time: 11977, easy_pace: 354, marathon_pace: 284, threshold_pace: 270, cv_pace: 259, interval_pace: 248, repetition_pace: 230 },
    { vdot: 49, full_marathon_time: 11753, easy_pace: 347, marathon_pace: 279, threshold_pace: 265, cv_pace: 254, interval_pace: 243, repetition_pace: 226 },
    { vdot: 50, full_marathon_time: 11530, easy_pace: 341, marathon_pace: 274, threshold_pace: 260, cv_pace: 249, interval_pace: 239, repetition_pace: 221 },
    { vdot: 51, full_marathon_time: 11306, easy_pace: 334, marathon_pace: 268, threshold_pace: 255, cv_pace: 244, interval_pace: 234, repetition_pace: 217 },
    { vdot: 52, full_marathon_time: 11083, easy_pace: 327, marathon_pace: 263, threshold_pace: 250, cv_pace: 239, interval_pace: 230, repetition_pace: 213 },
    { vdot: 53, full_marathon_time: 10860, easy_pace: 319, marathon_pace: 258, threshold_pace: 244, cv_pace: 234, interval_pace: 224, repetition_pace: 210 },
    { vdot: 54, full_marathon_time: 10727, easy_pace: 314, marathon_pace: 254, threshold_pace: 240, cv_pace: 231, interval_pace: 221, repetition_pace: 207 },
    { vdot: 55, full_marathon_time: 10561, easy_pace: 310, marathon_pace: 250, threshold_pace: 236, cv_pace: 227, interval_pace: 217, repetition_pace: 203 },
    { vdot: 56, full_marathon_time: 10400, easy_pace: 305, marathon_pace: 246, threshold_pace: 233, cv_pace: 224, interval_pace: 214, repetition_pace: 200 },
    { vdot: 57, full_marathon_time: 10245, easy_pace: 301, marathon_pace: 243, threshold_pace: 230, cv_pace: 221, interval_pace: 211, repetition_pace: 197 },
    { vdot: 58, full_marathon_time: 10094, easy_pace: 297, marathon_pace: 239, threshold_pace: 226, cv_pace: 217, interval_pace: 208, repetition_pace: 193 },
    { vdot: 59, full_marathon_time:  9947, easy_pace: 293, marathon_pace: 236, threshold_pace: 223, cv_pace: 214, interval_pace: 205, repetition_pace: 190 },
    { vdot: 60, full_marathon_time:  9805, easy_pace: 289, marathon_pace: 232, threshold_pace: 220, cv_pace: 212, interval_pace: 203, repetition_pace: 187 },
    { vdot: 61, full_marathon_time:  9668, easy_pace: 285, marathon_pace: 229, threshold_pace: 217, cv_pace: 209, interval_pace: 200, repetition_pace: 185 },
    { vdot: 62, full_marathon_time:  9534, easy_pace: 281, marathon_pace: 226, threshold_pace: 214, cv_pace: 206, interval_pace: 197, repetition_pace: 182 },
    { vdot: 63, full_marathon_time:  9404, easy_pace: 278, marathon_pace: 223, threshold_pace: 212, cv_pace: 204, interval_pace: 195, repetition_pace: 180 },
    { vdot: 64, full_marathon_time:  9278, easy_pace: 274, marathon_pace: 220, threshold_pace: 209, cv_pace: 201, interval_pace: 192, repetition_pace: 176 },
    { vdot: 65, full_marathon_time:  9120, easy_pace: 271, marathon_pace: 217, threshold_pace: 206, cv_pace: 198, interval_pace: 190, repetition_pace: 175 },
    { vdot: 66, full_marathon_time:  9036, easy_pace: 268, marathon_pace: 214, threshold_pace: 204, cv_pace: 196, interval_pace: 188, repetition_pace: 172 },
    { vdot: 67, full_marathon_time:  8939, easy_pace: 264, marathon_pace: 212, threshold_pace: 201, cv_pace: 193, interval_pace: 185, repetition_pace: 172 },
    { vdot: 68, full_marathon_time:  8842, easy_pace: 261, marathon_pace: 210, threshold_pace: 199, cv_pace: 191, interval_pace: 183, repetition_pace: 170 },
    { vdot: 69, full_marathon_time:  8745, easy_pace: 258, marathon_pace: 207, threshold_pace: 197, cv_pace: 189, interval_pace: 181, repetition_pace: 168 },
    { vdot: 70, full_marathon_time:  8648, easy_pace: 255, marathon_pace: 205, threshold_pace: 195, cv_pace: 187, interval_pace: 179, repetition_pace: 166 },
    { vdot: 71, full_marathon_time:  8551, easy_pace: 253, marathon_pace: 203, threshold_pace: 193, cv_pace: 185, interval_pace: 177, repetition_pace: 164 },
    { vdot: 72, full_marathon_time:  8454, easy_pace: 250, marathon_pace: 201, threshold_pace: 191, cv_pace: 183, interval_pace: 175, repetition_pace: 162 },
    { vdot: 73, full_marathon_time:  8357, easy_pace: 247, marathon_pace: 198, threshold_pace: 188, cv_pace: 181, interval_pace: 173, repetition_pace: 160 },
    { vdot: 74, full_marathon_time:  8260, easy_pace: 244, marathon_pace: 196, threshold_pace: 186, cv_pace: 178, interval_pace: 171, repetition_pace: 158 },
    { vdot: 75, full_marathon_time:  8163, easy_pace: 241, marathon_pace: 194, threshold_pace: 184, cv_pace: 176, interval_pace: 169, repetition_pace: 157 },
    { vdot: 76, full_marathon_time:  8066, easy_pace: 238, marathon_pace: 191, threshold_pace: 182, cv_pace: 174, interval_pace: 167, repetition_pace: 155 },
    { vdot: 77, full_marathon_time:  7969, easy_pace: 235, marathon_pace: 189, threshold_pace: 179, cv_pace: 172, interval_pace: 165, repetition_pace: 153 },
    { vdot: 78, full_marathon_time:  7872, easy_pace: 232, marathon_pace: 187, threshold_pace: 177, cv_pace: 170, interval_pace: 163, repetition_pace: 151 },
    { vdot: 79, full_marathon_time:  7775, easy_pace: 230, marathon_pace: 184, threshold_pace: 175, cv_pace: 168, interval_pace: 161, repetition_pace: 149 },
    { vdot: 80, full_marathon_time:  7678, easy_pace: 227, marathon_pace: 182, threshold_pace: 173, cv_pace: 166, interval_pace: 159, repetition_pace: 147 },
    { vdot: 81, full_marathon_time:  7581, easy_pace: 224, marathon_pace: 180, threshold_pace: 171, cv_pace: 164, interval_pace: 157, repetition_pace: 145 },
    { vdot: 82, full_marathon_time:  7484, easy_pace: 221, marathon_pace: 178, threshold_pace: 169, cv_pace: 162, interval_pace: 155, repetition_pace: 144 },
    { vdot: 83, full_marathon_time:  7387, easy_pace: 218, marathon_pace: 175, threshold_pace: 166, cv_pace: 160, interval_pace: 153, repetition_pace: 142 },
    { vdot: 84, full_marathon_time:  7290, easy_pace: 215, marathon_pace: 173, threshold_pace: 164, cv_pace: 157, interval_pace: 151, repetition_pace: 140 },
    { vdot: 85, full_marathon_time:  7193, easy_pace: 212, marathon_pace: 171, threshold_pace: 162, cv_pace: 155, interval_pace: 149, repetition_pace: 138 },
  ].freeze

  PACE_COLUMNS = %i[easy_pace marathon_pace threshold_pace cv_pace interval_pace repetition_pace].freeze

  def self.find_lower(marathon_time)
    TABLE.select { |r| r[:full_marathon_time] >= marathon_time }
         .min_by { |r| r[:full_marathon_time] }
  end

  def self.find_upper(marathon_time)
    TABLE.select { |r| r[:full_marathon_time] < marathon_time }
         .max_by { |r| r[:full_marathon_time] }
  end
end

//+------------------------------------------------------------------+
//|                                                  ICT_Project.mq5 |
//|                        Converted from Pine Script by AI Assistant |
//+------------------------------------------------------------------+
#property copyright "Jules"
#property link      "https://example.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#include <Arrays/ArrayObj.mqh>
#include <Charts/ChartObjects/ChartObjectsLines.mqh>
#include <Charts/ChartObjects/ChartObjectsTxt.mqh>

//--- Enums
enum ENUM_CALC_MODE {
   CALC_MODE_CURRENT, // Current Timeframe
   CALC_MODE_AUTO,    // Auto (Higher TF)
   CALC_MODE_FIXED    // Fixed Timeframe
};

enum ENUM_TEXT_SIZE_CUSTOM {
   SIZE_TINY_CUSTOM = 6,
   SIZE_SMALL_CUSTOM = 8,
   SIZE_NORMAL_CUSTOM = 10,
   SIZE_LARGE_CUSTOM = 12
};

//--- Inputs
input int      InpLookbackRange = 1500;       // Lookback Range

input group "Calculation Settings"
input ENUM_CALC_MODE InpCalcMode = CALC_MODE_CURRENT; // Calculation Mode
input ENUM_TIMEFRAMES InpFixedTf = PERIOD_D1;         // Fixed Timeframe

input group "HTF Visibility Limits"
input ENUM_TIMEFRAMES InpVisM  = PERIOD_D1;   // Monthly POIs Visible Down To
input ENUM_TIMEFRAMES InpVisW  = PERIOD_H4;   // Weekly POIs Visible Down To
input ENUM_TIMEFRAMES InpVisD  = PERIOD_H1;   // Daily POIs Visible Down To
input ENUM_TIMEFRAMES InpVis4H = PERIOD_D1;   // 4H POIs Visible Down To
input ENUM_TIMEFRAMES InpVis1H = PERIOD_H1;   // 1H POIs Visible Down To

input group "Style & Colors (RJ & Swings)"
input bool     InpShowRJ            = true;          // Show Rejection Blocks (RJ)
input color    InpRJColorBear       = clrPurple;     // RJ Bearish Color
input color    InpRJColorBull       = clrOrange;     // RJ Bullish Color
input bool     InpShowMtfSwings     = true;          // Show MTF Swings (High/Low)
input color    InpMtfSwingColorHigh = clrRed;        // Swing High Color
input color    InpMtfSwingColorLow  = clrGreen;      // Swing Low Color

input group "Mitigation Settings (Delay & Color)"
input int      InpMitigationDelay = 0;           // Mitigation Delay (HTF Bars Scaled)
input color    InpMitigationColor = clrGray;     // Mitigated Line Color

input group "Current Structure (Active)"
input ENUM_TIMEFRAMES InpMshMslMin = PERIOD_H1;  // Min Visibility
input ENUM_TIMEFRAMES InpMshMslMax = PERIOD_MN1; // Max Visibility
input color    InpMainColorHigh = clrRed;        // Active msH Color
input color    InpMainColorLow  = clrGreen;      // Active msL Color
input int      InpMainWidth     = 2;             // Active Line Width

input group "Historical Structure"
input bool     InpShowHist      = true;          // Show History
input color    InpHistColorHigh = clrGray;       // History msH
input color    InpHistColorLow  = clrGray;       // History msL
input int      InpHistWidth     = 1;             // Width
input ENUM_LINE_STYLE InpHistStyle = STYLE_DOT;  // Style

input group "Minor Structure Swings"
input bool     InpShowMinorSwings = false;       // Show Minor Swings
input ENUM_TIMEFRAMES InpMinorMin = PERIOD_H1;   // Min Visibility
input ENUM_TIMEFRAMES InpMinorMax = PERIOD_MN1;  // Max Visibility
input color    InpMinorColorHigh  = clrRed;      // Minor High
input color    InpMinorColorLow   = clrGreen;    // Minor Low
input ENUM_LINE_STYLE InpMinorStyle = STYLE_DOT; // Style
input int      InpMinorWidth      = 1;           // Width

input group "Raid Candles"
input color    InpRaidColorBear = clrYellow;     // Bearish Raid
input color    InpRaidColorBull = clrAqua;       // Bullish Raid

input group "EXTRA: Weekly High/Low Settings"
input color    InpPwhColor = clrGreen;           // Previous Week High (pwH) Color
input color    InpPwlColor = clrRed;             // Previous Week Low (pwL) Color

input group "EXTRA: Daily High/Low Settings"
input color    InpYhColor  = clrBlue;            // Previous Day High (yH) Color
input color    InpYlColor  = clrOrange;          // Previous Day Low (yL) Color

input group "EXTRA: Common Settings"
input int      InpLineWidthExtra = 1;            // Line Width
input ENUM_TEXT_SIZE_CUSTOM InpTextSizeExtra = SIZE_SMALL_CUSTOM; // Label Size

//--- Classes
class CBaseICTObject : public CObject {
public:
   string   m_line_name;
   string   m_label_name;
   double   m_price;
   bool     m_is_high_bearish;
   int      m_mitigated_count;
   double   m_tf_ratio;
   string   m_tf_name;

   CBaseICTObject() : m_mitigated_count(-1), m_price(0), m_tf_ratio(1.0) {}

   ~CBaseICTObject() {
      DeleteVisuals();
   }

   void CreateVisuals(string prefix, datetime t1, datetime t2, double price, color clr, int width, ENUM_LINE_STYLE style, string text, int text_size, color text_clr) {
      m_line_name = prefix + "_Ln_" + IntegerToString(t1) + "_" + DoubleToString(price, 5) + "_" + IntegerToString(MathRand());
      m_label_name = prefix + "_Lb_" + IntegerToString(t1) + "_" + DoubleToString(price, 5) + "_" + IntegerToString(MathRand());
      m_price = price;

      ObjectCreate(0, m_line_name, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, m_line_name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, m_line_name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, m_line_name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, m_line_name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, m_line_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_line_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, m_line_name, OBJPROP_SELECTED, false);

      ObjectCreate(0, m_label_name, OBJ_TEXT, 0, t2, price);
      ObjectSetString(0, m_label_name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, m_label_name, OBJPROP_COLOR, text_clr);
      ObjectSetInteger(0, m_label_name, OBJPROP_FONTSIZE, text_size);
      ObjectSetInteger(0, m_label_name, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(0, m_label_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, m_label_name, OBJPROP_SELECTED, false);
   }

   void DeleteVisuals() {
      if(ObjectFind(0, m_line_name) >= 0) ObjectDelete(0, m_line_name);
      if(ObjectFind(0, m_label_name) >= 0) ObjectDelete(0, m_label_name);
   }

   void UpdateVisuals(datetime t_current, color c_line, color c_text) {
       ObjectSetInteger(0, m_line_name, OBJPROP_TIME2, t_current);
       ObjectSetInteger(0, m_label_name, OBJPROP_TIME, t_current);

       if(c_line != clrNONE) ObjectSetInteger(0, m_line_name, OBJPROP_COLOR, c_line);
       if(c_text != clrNONE) ObjectSetInteger(0, m_label_name, OBJPROP_COLOR, c_text);
   }
};

class CRJO : public CBaseICTObject {
public:
   CRJO(datetime t1, datetime t2, double price, bool isBear, string tf, double ratio) {
      m_is_high_bearish = isBear;
      m_tf_name = tf;
      m_tf_ratio = ratio;
      color c = isBear ? InpRJColorBear : InpRJColorBull;
      CreateVisuals("ICT_Proj_RJ", t1, t2, price, c, 1, STYLE_SOLID, "RJ-" + tf, 8, c);
   }
};

class CMtfSwing : public CBaseICTObject {
public:
   CMtfSwing(datetime t1, datetime t2, double price, bool isHigh, string tf, double ratio) {
      m_is_high_bearish = isHigh;
      m_tf_name = tf;
      m_tf_ratio = ratio;
      color c = isHigh ? InpMtfSwingColorHigh : InpMtfSwingColorLow;
      CreateVisuals("ICT_Proj_Sw", t1, t2, price, c, InpMinorWidth, InpMinorStyle, "Sw" + (isHigh?"H":"L") + "-" + tf, 8, c);
   }
};

class CStructureLine : public CBaseICTObject {
public:
   CStructureLine(datetime t1, datetime t2, double price, bool isHigh, bool isHistory) {
      m_is_high_bearish = isHigh;
      color c = isHigh ? (isHistory ? InpHistColorHigh : InpMainColorHigh) : (isHistory ? InpHistColorLow : InpMainColorLow);

      // Visibility check for history
      if (isHistory && !InpShowHist) {
          c = clrNONE;
      }

      int w = isHistory ? InpHistWidth : InpMainWidth;
      ENUM_LINE_STYLE st = isHistory ? InpHistStyle : STYLE_SOLID;
      string txt = isHigh ? "msH" : "msL";

      CreateVisuals("ICT_Proj_St", t1, t2, price, c, w, st, txt, 8, c);
   }
};

class CMinorSwing : public CBaseICTObject {
public:
   CMinorSwing(datetime t1, datetime t2, double price, bool isHigh, double ratio) {
      m_is_high_bearish = isHigh;
      m_tf_ratio = ratio;
      color c = isHigh ? InpMinorColorHigh : InpMinorColorLow;
      CreateVisuals("ICT_Proj_Mn", t1, t2, price, c, InpMinorWidth, InpMinorStyle, isHigh?"Sw-H":"Sw-L", 8, c);
   }
};

//--- Global Variables
CArrayObj activeRJs;
CArrayObj activeMtfSwings;
CArrayObj historyStructures;
CArrayObj activeMinorSwings;

// State Variables for Main Structure
double   rangeHighPrice = 0.0;
datetime rangeHighTime  = 0;
string   lineHighName   = "";
string   labelHighName  = "";

double   rangeLowPrice  = 0.0;
datetime rangeLowTime   = 0;
string   lineLowName    = "";
string   labelLowName   = "";

double   lastKnownSwingHighPrice = 0.0;
datetime lastKnownSwingHighTime  = 0;
double   lastKnownSwingLowPrice  = 0.0;
datetime lastKnownSwingLowTime   = 0;

int      state = 0;

//--- MTF Buffer Struct
struct SMTFBuffer {
   double h[3];
   double l[3];
   double c[3];
   double o[3];
   datetime t[3];

   SMTFBuffer() {
      ArrayInitialize(h, 0); ArrayInitialize(l, 0);
      ArrayInitialize(c, 0); ArrayInitialize(o, 0);
      ArrayInitialize(t, 0);
   }

   void Push(double _h, double _l, double _c, double _o, datetime _t) {
      h[2]=h[1]; h[1]=h[0]; h[0]=_h;
      l[2]=l[1]; l[1]=l[0]; l[0]=_l;
      c[2]=c[1]; c[1]=c[0]; c[0]=_c;
      o[2]=o[1]; o[1]=o[0]; o[0]=_o;
      t[2]=t[1]; t[1]=t[0]; t[0]=_t;
   }

   double H(int i) { return h[i]; }
   double L(int i) { return l[i]; }
   double C(int i) { return c[i]; }
   double O(int i) { return o[i]; }
   datetime T(int i) { return t[i]; }

   double BodyTop(int i) { return MathMax(o[i], c[i]); }
   double BodyBot(int i) { return MathMin(o[i], c[i]); }
};

SMTFBuffer buf_Local, buf_1H, buf_4H, buf_D, buf_W, buf_M;

//--- Helper Functions
string GetTimeframeName(ENUM_TIMEFRAMES tf) {
   switch(tf) {
      case PERIOD_M1: return "1m";
      case PERIOD_M5: return "5m";
      case PERIOD_M15: return "15m";
      case PERIOD_M30: return "30m";
      case PERIOD_H1: return "1h";
      case PERIOD_H4: return "4h";
      case PERIOD_D1: return "D";
      case PERIOD_W1: return "W";
      case PERIOD_MN1: return "M";
      default: return EnumToString(tf);
   }
}

void CreateBOSVisuals(datetime t_start, datetime t_end, double price, color c) {
    string sName = "ICT_Proj_BOS_Ln_" + IntegerToString(t_start) + "_" + IntegerToString(MathRand());
    ObjectCreate(0, sName, OBJ_TREND, 0, t_start, price, t_end, price);
    ObjectSetInteger(0, sName, OBJPROP_COLOR, c);
    ObjectSetInteger(0, sName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, sName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, sName, OBJPROP_RAY_RIGHT, false);

    datetime t_mid = (t_start + t_end) / 2;
    string lName = "ICT_Proj_BOS_Lb_" + IntegerToString(t_start) + "_" + IntegerToString(MathRand());
    ObjectCreate(0, lName, OBJ_TEXT, 0, t_mid, price);
    ObjectSetString(0, lName, OBJPROP_TEXT, "BOS");
    ObjectSetInteger(0, lName, OBJPROP_COLOR, c);
    ObjectSetInteger(0, lName, OBJPROP_FONTSIZE, SIZE_SMALL_CUSTOM);
    ObjectSetInteger(0, lName, OBJPROP_ANCHOR, ANCHOR_CENTER);
}

//--- Logic Functions

void CheckMitigation(double high, double low, datetime t) {
   // 1. RJs
   for(int i = activeRJs.Total() - 1; i >= 0; i--) {
      CRJO *obj = (CRJO*)activeRJs.At(i);
      if(!obj) continue;

      bool touched = false;
      if(obj.m_is_high_bearish) {
         if(high >= obj.m_price) touched = true;
      } else {
         if(low <= obj.m_price) touched = true;
      }

      if(touched) {
         if(obj.m_mitigated_count == -1) obj.m_mitigated_count = 0;

         double delay = InpMitigationDelay * obj.m_tf_ratio;
         if(obj.m_mitigated_count >= delay) {
            activeRJs.Delete(i);
         } else {
            obj.m_mitigated_count++;
            obj.UpdateVisuals(t, InpMitigationColor, InpMitigationColor);
         }
      } else {
         obj.UpdateVisuals(t, clrNONE, clrNONE);
      }
   }

   // 2. MTF Swings
   for(int i = activeMtfSwings.Total() - 1; i >= 0; i--) {
      CMtfSwing *obj = (CMtfSwing*)activeMtfSwings.At(i);
      if(!obj) continue;

      bool touched = false;
      if(obj.m_is_high_bearish) {
         if(high >= obj.m_price) touched = true;
      } else {
         if(low <= obj.m_price) touched = true;
      }

      if(touched) {
         if(obj.m_mitigated_count == -1) obj.m_mitigated_count = 0;

         double delay = InpMitigationDelay * obj.m_tf_ratio;
         if(obj.m_mitigated_count >= delay) {
            activeMtfSwings.Delete(i);
         } else {
            obj.m_mitigated_count++;
            obj.UpdateVisuals(t, InpMitigationColor, InpMitigationColor);
         }
      } else {
         obj.UpdateVisuals(t, clrNONE, clrNONE);
      }
   }

   // 3. History Structures
   for(int i = historyStructures.Total() - 1; i >= 0; i--) {
      CStructureLine *obj = (CStructureLine*)historyStructures.At(i);
      if(!obj) continue;

      bool touched = false;
      if(obj.m_is_high_bearish) {
         if(high >= obj.m_price) touched = true;
      } else {
         if(low <= obj.m_price) touched = true;
      }

      if(touched) {
         if(obj.m_mitigated_count == -1) obj.m_mitigated_count = 0;

         double delay = InpMitigationDelay;
         if(obj.m_mitigated_count >= delay) {
            historyStructures.Delete(i);
         } else {
            obj.m_mitigated_count++;
            obj.UpdateVisuals(t, InpMitigationColor, InpMitigationColor);
         }
      } else {
         obj.UpdateVisuals(t, clrNONE, clrNONE);
      }
   }

   // 4. Minor Swings
   for(int i = activeMinorSwings.Total() - 1; i >= 0; i--) {
      CMinorSwing *obj = (CMinorSwing*)activeMinorSwings.At(i);
      if(!obj) continue;

      bool touched = false;
      if(obj.m_is_high_bearish) {
         if(high >= obj.m_price) touched = true;
      } else {
         if(low <= obj.m_price) touched = true;
      }

      if(touched) {
         if(obj.m_mitigated_count == -1) obj.m_mitigated_count = 0;

         double delay = InpMitigationDelay * obj.m_tf_ratio;
         if(obj.m_mitigated_count >= delay) {
            activeMinorSwings.Delete(i);
         } else {
            obj.m_mitigated_count++;
            obj.UpdateVisuals(t, InpMitigationColor, InpMitigationColor);
         }
      } else {
         obj.UpdateVisuals(t, clrNONE, clrNONE);
      }
   }
}

void ProcessMTF(ENUM_TIMEFRAMES tf, SMTFBuffer &buf, ENUM_TIMEFRAMES limitTf, datetime curTime) {
   int curSec = PeriodSeconds(PERIOD_CURRENT);
   int targetSec = PeriodSeconds(tf);
   int limitSec = PeriodSeconds(limitTf);

   double ratio = (double)targetSec / (double)curSec;
   if(ratio < 1.0) ratio = 1.0;

   bool isVisible = (targetSec >= curSec) && (curSec >= limitSec);
   bool allowRJ = targetSec > 14400; // > 4 Hours

   bool processAny = (InpShowRJ || InpShowMtfSwings) && isVisible;
   if(!processAny) return;

   int shift = iBarShift(Symbol(), tf, curTime, false);
   // Get time of the LAST COMPLETED bar (shift + 1)
   datetime t1 = iTime(Symbol(), tf, shift + 1);

   if(t1 == 0) return;

   // New bar check
   if(t1 > buf.t[0]) {
      double h = iHigh(Symbol(), tf, shift + 1);
      double l = iLow(Symbol(), tf, shift + 1);
      double c = iClose(Symbol(), tf, shift + 1);
      double o = iOpen(Symbol(), tf, shift + 1);

      buf.Push(h, l, c, o, t1);

      if(buf.h[0] == 0 || buf.h[2] == 0) return; // Need 3 bars

      // Buffer indices: [0]=Newest, [1]=Middle, [2]=Oldest
      double h_new = buf.h[0];
      double h_mid = buf.h[1];
      double h_old = buf.h[2];

      double l_new = buf.l[0];
      double l_mid = buf.l[1];
      double l_old = buf.l[2];

      datetime t_mid = buf.t[1];
      datetime t_new = buf.t[0];

      bool swH = h_mid > h_old && h_mid > h_new;
      bool swL = l_mid < l_old && l_mid < l_new;

      string tfLabel = GetTimeframeName(tf);

      if(swH) {
         if(InpShowRJ && allowRJ) {
            double maxBody = MathMax(buf.BodyTop(0), MathMax(buf.BodyTop(1), buf.BodyTop(2)));
            // Draw from Middle to Newest to show the swing level formation
            activeRJs.Add(new CRJO(t_mid, t_new, maxBody, true, tfLabel, ratio));
         }
         if(InpShowMtfSwings) {
             activeMtfSwings.Add(new CMtfSwing(t_mid, t_new, h_mid, true, tfLabel, ratio));
         }
      }

      if(swL) {
         if(InpShowRJ && allowRJ) {
            double minBody = MathMin(buf.BodyBot(0), MathMin(buf.BodyBot(1), buf.BodyBot(2)));
            activeRJs.Add(new CRJO(t_mid, t_new, minBody, false, tfLabel, ratio));
         }
         if(InpShowMtfSwings) {
             activeMtfSwings.Add(new CMtfSwing(t_mid, t_new, l_mid, false, tfLabel, ratio));
         }
      }
   }
}

ENUM_TIMEFRAMES GetAutoTf() {
   int t = PeriodSeconds();
   if(t < 3600) return PERIOD_H1;
   if(t < 14400) return PERIOD_H4;
   if(t < 86400) return PERIOD_D1;
   if(t < 604800) return PERIOD_W1;
   return PERIOD_MN1;
}

//+------------------------------------------------------------------+
//| Custom Indicator Initialization Function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Enable Memory Management
   activeRJs.FreeMode(true);
   activeMtfSwings.FreeMode(true);
   historyStructures.FreeMode(true);
   activeMinorSwings.FreeMode(true);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom Indicator Deinitialization Function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   activeRJs.Clear();
   activeMtfSwings.Clear();
   historyStructures.Clear();
   activeMinorSwings.Clear();

   // Cleanup all objects
   ObjectsDeleteAll(0, "ICT_Proj_");
  }

//+------------------------------------------------------------------+
//| Custom Indicator Iteration Function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < InpLookbackRange) return(0);

   if(prev_calculated == 0) {
      state = 0;
      rangeHighPrice = 0.0; rangeHighTime = 0;
      rangeLowPrice = 0.0; rangeLowTime = 0;
      lastKnownSwingHighPrice = 0.0; lastKnownSwingHighTime = 0;
      lastKnownSwingLowPrice = 0.0; lastKnownSwingLowTime = 0;
      lineHighName = ""; labelHighName = "";
      lineLowName = ""; labelLowName = "";

      activeRJs.Clear();
      activeMtfSwings.Clear();
      historyStructures.Clear();
      activeMinorSwings.Clear();
      ObjectsDeleteAll(0, "ICT_Proj_");
   }

   int start_index = prev_calculated - 1;
   if(prev_calculated == 0) start_index = rates_total - InpLookbackRange;
   if(start_index < 0) start_index = 0;

   ENUM_TIMEFRAMES targetTf = InpFixedTf;
   if(InpCalcMode == CALC_MODE_CURRENT) targetTf = PERIOD_CURRENT;
   else if(InpCalcMode == CALC_MODE_AUTO) targetTf = GetAutoTf();

   double mainStructureRatio = (double)PeriodSeconds(targetTf) / (double)PeriodSeconds(PERIOD_CURRENT);
   if(mainStructureRatio < 1.0) mainStructureRatio = 1.0;

   bool allowLocalExecution = PeriodSeconds(PERIOD_CURRENT) >= 3600;

   // Main Loop
   for(int i = start_index; i < rates_total; i++) {
      datetime t = time[i];
      double h = high[i];
      double l = low[i];
      double c = close[i];
      double o = open[i];

      // 1. Mitigation
      CheckMitigation(h, l, t);

      // 2. MTF Logic
      if(i > 0) {
         ProcessMTF(PERIOD_H1, buf_1H, InpVis1H, t);
         ProcessMTF(PERIOD_H4, buf_4H, InpVis4H, t);
         ProcessMTF(PERIOD_D1, buf_D, InpVisD, t);
         ProcessMTF(PERIOD_W1, buf_W, InpVisW, t);
         ProcessMTF(PERIOD_MN1, buf_M, InpVisM, t);
      }

      // 3. Main Structure Logic
      bool isConfirmed = true;
      if(targetTf == PERIOD_CURRENT) {
         if(i == rates_total - 1) isConfirmed = false;
      }

      int shift = 0;
      datetime t_target = 0;
      double src_h=0, src_l=0, src_c=0, src_o=0;

      if(targetTf == PERIOD_CURRENT) {
         shift = 0;
         t_target = t;
         src_h=h; src_l=l; src_c=c; src_o=o;
      } else {
         shift = iBarShift(Symbol(), targetTf, t, false);
         datetime completed_time = iTime(Symbol(), targetTf, shift + 1);
         if(completed_time > buf_Local.t[0] && completed_time != 0) {
             t_target = completed_time;
             src_h = iHigh(Symbol(), targetTf, shift+1);
             src_l = iLow(Symbol(), targetTf, shift+1);
             src_c = iClose(Symbol(), targetTf, shift+1);
             src_o = iOpen(Symbol(), targetTf, shift+1);
         } else {
             t_target = 0;
         }
      }

      if(targetTf == PERIOD_CURRENT && !isConfirmed) t_target = 0;

      if(t_target != 0 && (targetTf == PERIOD_CURRENT || t_target > buf_Local.t[0])) {
         buf_Local.Push(src_h, src_l, src_c, src_o, t_target);

         if(buf_Local.h[0] != 0 && buf_Local.h[2] != 0) {
            double h_new = buf_Local.h[0];
            double h_mid = buf_Local.h[1];
            double h_old = buf_Local.h[2];
            double l_new = buf_Local.l[0];
            double l_mid = buf_Local.l[1];
            double l_old = buf_Local.l[2];

            datetime t_new = buf_Local.t[0];
            datetime t_mid = buf_Local.t[1];

            bool swH = h_mid > h_old && h_mid > h_new;
            bool swL = l_mid < l_old && l_mid < l_new;

            // Local Swings
            if(allowLocalExecution) {
               if(swH) {
                  lastKnownSwingHighPrice = h_mid;
                  lastKnownSwingHighTime = t_mid;
                  if(InpShowMinorSwings) {
                      activeMinorSwings.Add(new CMinorSwing(t_mid, t_new, h_mid, true, mainStructureRatio));
                  }
               }
               if(swL) {
                  lastKnownSwingLowPrice = l_mid;
                  lastKnownSwingLowTime = t_mid;
                  if(InpShowMinorSwings) {
                      activeMinorSwings.Add(new CMinorSwing(t_mid, t_new, l_mid, false, mainStructureRatio));
                  }
               }
            }

            // State Machine
            double currentClose = buf_Local.c[0];

            color cMainHigh = InpMainColorHigh;
            color cMainLow = InpMainColorLow;

            if(state == 0) {
               if(rangeHighPrice == 0.0 && lastKnownSwingHighPrice != 0.0) {
                  rangeHighPrice = lastKnownSwingHighPrice;
                  rangeHighTime = lastKnownSwingHighTime;
                  // Draw Line H
                  lineHighName = "ICT_Proj_StH_" + IntegerToString(rangeHighTime);
                  labelHighName = "ICT_Proj_LbH_" + IntegerToString(rangeHighTime);
                  ObjectCreate(0, lineHighName, OBJ_TREND, 0, rangeHighTime, rangeHighPrice, t_new, rangeHighPrice);
                  ObjectSetInteger(0, lineHighName, OBJPROP_COLOR, cMainHigh);
                  ObjectSetInteger(0, lineHighName, OBJPROP_WIDTH, InpMainWidth);
                  ObjectSetInteger(0, lineHighName, OBJPROP_RAY_RIGHT, true);

                  ObjectCreate(0, labelHighName, OBJ_TEXT, 0, rangeHighTime, rangeHighPrice);
                  ObjectSetString(0, labelHighName, OBJPROP_TEXT, "H");
                  ObjectSetInteger(0, labelHighName, OBJPROP_COLOR, cMainHigh);
               }
               if(rangeLowPrice == 0.0 && lastKnownSwingLowPrice != 0.0) {
                   rangeLowPrice = lastKnownSwingLowPrice;
                   rangeLowTime = lastKnownSwingLowTime;
                   // Draw Line L
                   lineLowName = "ICT_Proj_StL_" + IntegerToString(rangeLowTime);
                   labelLowName = "ICT_Proj_LbL_" + IntegerToString(rangeLowTime);
                   ObjectCreate(0, lineLowName, OBJ_TREND, 0, rangeLowTime, rangeLowPrice, t_new, rangeLowPrice);
                   ObjectSetInteger(0, lineLowName, OBJPROP_COLOR, cMainLow);
                   ObjectSetInteger(0, lineLowName, OBJPROP_WIDTH, InpMainWidth);
                   ObjectSetInteger(0, lineLowName, OBJPROP_RAY_RIGHT, true);

                   ObjectCreate(0, labelLowName, OBJ_TEXT, 0, rangeLowTime, rangeLowPrice);
                   ObjectSetString(0, labelLowName, OBJPROP_TEXT, "L");
                   ObjectSetInteger(0, labelLowName, OBJPROP_COLOR, cMainLow);
               }
               if(rangeHighPrice != 0.0 && rangeLowPrice != 0.0) state = 1;
            } else if(state == 1) {
                // Update Lines
                ObjectSetInteger(0, lineHighName, OBJPROP_TIME2, t_new);
                ObjectSetInteger(0, lineLowName, OBJPROP_TIME2, t_new);

                // BOS Check
                if(currentClose > rangeHighPrice) {
                   // Bullish BOS
                   CreateBOSVisuals(rangeHighTime, t_new, rangeHighPrice, clrBlue);

                   ObjectDelete(0, lineHighName); ObjectDelete(0, labelHighName);
                   historyStructures.Add(new CStructureLine(rangeHighTime, t_new, rangeHighPrice, true, true));

                   ObjectDelete(0, lineLowName); ObjectDelete(0, labelLowName);
                   historyStructures.Add(new CStructureLine(rangeLowTime, t_new, rangeLowPrice, false, true));

                   // New L
                   rangeLowPrice = lastKnownSwingLowPrice;
                   rangeLowTime = lastKnownSwingLowTime;

                   lineLowName = "ICT_Proj_StL_" + IntegerToString(rangeLowTime) + "_" + IntegerToString(MathRand());
                   labelLowName = "ICT_Proj_LbL_" + IntegerToString(rangeLowTime) + "_" + IntegerToString(MathRand());
                   ObjectCreate(0, lineLowName, OBJ_TREND, 0, rangeLowTime, rangeLowPrice, t_new, rangeLowPrice);
                   ObjectSetInteger(0, lineLowName, OBJPROP_COLOR, cMainLow);
                   ObjectSetInteger(0, lineLowName, OBJPROP_WIDTH, InpMainWidth);
                   ObjectSetInteger(0, lineLowName, OBJPROP_RAY_RIGHT, true);
                   ObjectCreate(0, labelLowName, OBJ_TEXT, 0, rangeLowTime, rangeLowPrice);
                   ObjectSetString(0, labelLowName, OBJPROP_TEXT, "msL");

                   rangeHighPrice = 0.0;
                   state = 2;
                } else if(currentClose < rangeLowPrice) {
                   // Bearish BOS
                   CreateBOSVisuals(rangeLowTime, t_new, rangeLowPrice, clrOrange);

                   ObjectDelete(0, lineLowName); ObjectDelete(0, labelLowName);
                   historyStructures.Add(new CStructureLine(rangeLowTime, t_new, rangeLowPrice, false, true));

                   ObjectDelete(0, lineHighName); ObjectDelete(0, labelHighName);
                   historyStructures.Add(new CStructureLine(rangeHighTime, t_new, rangeHighPrice, true, true));

                   rangeHighPrice = lastKnownSwingHighPrice;
                   rangeHighTime = lastKnownSwingHighTime;

                   lineHighName = "ICT_Proj_StH_" + IntegerToString(rangeHighTime) + "_" + IntegerToString(MathRand());
                   labelHighName = "ICT_Proj_LbH_" + IntegerToString(rangeHighTime) + "_" + IntegerToString(MathRand());
                   ObjectCreate(0, lineHighName, OBJ_TREND, 0, rangeHighTime, rangeHighPrice, t_new, rangeHighPrice);
                   ObjectSetInteger(0, lineHighName, OBJPROP_COLOR, cMainHigh);
                   ObjectSetInteger(0, lineHighName, OBJPROP_WIDTH, InpMainWidth);
                   ObjectSetInteger(0, lineHighName, OBJPROP_RAY_RIGHT, true);
                   ObjectCreate(0, labelHighName, OBJ_TEXT, 0, rangeHighTime, rangeHighPrice);
                   ObjectSetString(0, labelHighName, OBJPROP_TEXT, "msH");

                   rangeLowPrice = 0.0;
                   state = 3;
                }
            } else if(state == 2) {
               ObjectSetInteger(0, lineLowName, OBJPROP_TIME2, t_new);
               if(swH && h_mid > rangeLowPrice) {
                  rangeHighPrice = h_mid;
                  rangeHighTime = t_mid;
                  lineHighName = "ICT_Proj_StH_" + IntegerToString(rangeHighTime) + "_" + IntegerToString(MathRand());
                  labelHighName = "ICT_Proj_LbH_" + IntegerToString(rangeHighTime) + "_" + IntegerToString(MathRand());
                  ObjectCreate(0, lineHighName, OBJ_TREND, 0, rangeHighTime, rangeHighPrice, t_new, rangeHighPrice);
                  ObjectSetInteger(0, lineHighName, OBJPROP_COLOR, cMainHigh);
                  ObjectSetInteger(0, lineHighName, OBJPROP_WIDTH, InpMainWidth);
                  ObjectSetInteger(0, lineHighName, OBJPROP_RAY_RIGHT, true);
                  ObjectCreate(0, labelHighName, OBJ_TEXT, 0, rangeHighTime, rangeHighPrice);
                  ObjectSetString(0, labelHighName, OBJPROP_TEXT, "H");
                  state = 1;
               }
               if(currentClose < rangeLowPrice) {
                  ObjectDelete(0, lineLowName); ObjectDelete(0, labelLowName);
                  rangeLowPrice = 0.0;
                  state = 0;
               }
            } else if(state == 3) {
               ObjectSetInteger(0, lineHighName, OBJPROP_TIME2, t_new);
               if(swL && l_mid < rangeHighPrice) {
                  rangeLowPrice = l_mid;
                  rangeLowTime = t_mid;
                  lineLowName = "ICT_Proj_StL_" + IntegerToString(rangeLowTime) + "_" + IntegerToString(MathRand());
                  labelLowName = "ICT_Proj_LbL_" + IntegerToString(rangeLowTime) + "_" + IntegerToString(MathRand());
                  ObjectCreate(0, lineLowName, OBJ_TREND, 0, rangeLowTime, rangeLowPrice, t_new, rangeLowPrice);
                  ObjectSetInteger(0, lineLowName, OBJPROP_COLOR, cMainLow);
                  ObjectSetInteger(0, lineLowName, OBJPROP_WIDTH, InpMainWidth);
                  ObjectSetInteger(0, lineLowName, OBJPROP_RAY_RIGHT, true);
                  ObjectCreate(0, labelLowName, OBJ_TEXT, 0, rangeLowTime, rangeLowPrice);
                  ObjectSetString(0, labelLowName, OBJPROP_TEXT, "L");
                  state = 1;
               }
               if(currentClose > rangeHighPrice) {
                  ObjectDelete(0, lineHighName); ObjectDelete(0, labelHighName);
                  rangeHighPrice = 0.0;
                  state = 0;
               }
            }
         }
      }
   }

   // PWH/PDL Logic (Runs on Last Bar)
   datetime curTime = time[rates_total-1];
   int dShift = iBarShift(Symbol(), PERIOD_D1, curTime, false);
   datetime dStart = iTime(Symbol(), PERIOD_D1, dShift);
   int wShift = iBarShift(Symbol(), PERIOD_W1, curTime, false);
   datetime wStart = iTime(Symbol(), PERIOD_W1, wShift);

   double wHigh = iHigh(Symbol(), PERIOD_W1, wShift+1);
   double wLow = iLow(Symbol(), PERIOD_W1, wShift+1);
   double dHigh = iHigh(Symbol(), PERIOD_D1, dShift+1);
   double dLow = iLow(Symbol(), PERIOD_D1, dShift+1);

   int secCur = PeriodSeconds(PERIOD_CURRENT);
   bool showW = secCur <= PeriodSeconds(PERIOD_W1) && secCur >= PeriodSeconds(InpVisW);
   bool showD = secCur <= PeriodSeconds(PERIOD_D1) && secCur >= PeriodSeconds(InpVisD);

   if(showW) {
      // Draw PWH
      string namePWH = "ICT_Proj_PWH";
      if(ObjectFind(0, namePWH) < 0) ObjectCreate(0, namePWH, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, namePWH, OBJPROP_TIME, wStart);
      ObjectSetDouble(0, namePWH, OBJPROP_PRICE, wHigh);
      ObjectSetInteger(0, namePWH, OBJPROP_TIME2, curTime);
      ObjectSetDouble(0, namePWH, OBJPROP_PRICE2, wHigh);
      ObjectSetInteger(0, namePWH, OBJPROP_COLOR, InpPwhColor);

      // Label PWH
      string lblPWH = "ICT_Proj_LblPWH";
      if(ObjectFind(0, lblPWH) < 0) ObjectCreate(0, lblPWH, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, lblPWH, OBJPROP_TIME, curTime);
      ObjectSetDouble(0, lblPWH, OBJPROP_PRICE, wHigh);
      ObjectSetString(0, lblPWH, OBJPROP_TEXT, "  pwH");
      ObjectSetInteger(0, lblPWH, OBJPROP_COLOR, InpPwhColor);
      ObjectSetInteger(0, lblPWH, OBJPROP_ANCHOR, ANCHOR_LEFT);

      // Draw PWL
      string namePWL = "ICT_Proj_PWL";
      if(ObjectFind(0, namePWL) < 0) ObjectCreate(0, namePWL, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, namePWL, OBJPROP_TIME, wStart);
      ObjectSetDouble(0, namePWL, OBJPROP_PRICE, wLow);
      ObjectSetInteger(0, namePWL, OBJPROP_TIME2, curTime);
      ObjectSetDouble(0, namePWL, OBJPROP_PRICE2, wLow);
      ObjectSetInteger(0, namePWL, OBJPROP_COLOR, InpPwlColor);

      string lblPWL = "ICT_Proj_LblPWL";
      if(ObjectFind(0, lblPWL) < 0) ObjectCreate(0, lblPWL, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, lblPWL, OBJPROP_TIME, curTime);
      ObjectSetDouble(0, lblPWL, OBJPROP_PRICE, wLow);
      ObjectSetString(0, lblPWL, OBJPROP_TEXT, "  pwL");
      ObjectSetInteger(0, lblPWL, OBJPROP_COLOR, InpPwlColor);
      ObjectSetInteger(0, lblPWL, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }

   if(showD) {
      // Draw YH
      string nameYH = "ICT_Proj_YH";
      if(ObjectFind(0, nameYH) < 0) ObjectCreate(0, nameYH, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, nameYH, OBJPROP_TIME, dStart);
      ObjectSetDouble(0, nameYH, OBJPROP_PRICE, dHigh);
      ObjectSetInteger(0, nameYH, OBJPROP_TIME2, curTime);
      ObjectSetDouble(0, nameYH, OBJPROP_PRICE2, dHigh);
      ObjectSetInteger(0, nameYH, OBJPROP_COLOR, InpYhColor);

      string lblYH = "ICT_Proj_LblYH";
      if(ObjectFind(0, lblYH) < 0) ObjectCreate(0, lblYH, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, lblYH, OBJPROP_TIME, curTime);
      ObjectSetDouble(0, lblYH, OBJPROP_PRICE, dHigh);
      ObjectSetString(0, lblYH, OBJPROP_TEXT, "  yH");
      ObjectSetInteger(0, lblYH, OBJPROP_COLOR, InpYhColor);
      ObjectSetInteger(0, lblYH, OBJPROP_ANCHOR, ANCHOR_LEFT);

      // Draw YL
      string nameYL = "ICT_Proj_YL";
      if(ObjectFind(0, nameYL) < 0) ObjectCreate(0, nameYL, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, nameYL, OBJPROP_TIME, dStart);
      ObjectSetDouble(0, nameYL, OBJPROP_PRICE, dLow);
      ObjectSetInteger(0, nameYL, OBJPROP_TIME2, curTime);
      ObjectSetDouble(0, nameYL, OBJPROP_PRICE2, dLow);
      ObjectSetInteger(0, nameYL, OBJPROP_COLOR, InpYlColor);

      string lblYL = "ICT_Proj_LblYL";
      if(ObjectFind(0, lblYL) < 0) ObjectCreate(0, lblYL, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, lblYL, OBJPROP_TIME, curTime);
      ObjectSetDouble(0, lblYL, OBJPROP_PRICE, dLow);
      ObjectSetString(0, lblYL, OBJPROP_TEXT, "  yL");
      ObjectSetInteger(0, lblYL, OBJPROP_COLOR, InpYlColor);
      ObjectSetInteger(0, lblYL, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }

   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  ICT_Project.mq5 |
//|                                 Copyright 2024, Jules AI Dev |
//|                                         https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules AI Dev"
#property link      "https://www.mql5.com"
#property version   "1.03"
#property indicator_chart_window
#property indicator_buffers 24
#property indicator_plots   24

//--- Plot settings
#property indicator_type1   DRAW_NONE
#property indicator_type2   DRAW_NONE
#property indicator_type3   DRAW_NONE
#property indicator_type4   DRAW_NONE
#property indicator_type5   DRAW_NONE
#property indicator_type6   DRAW_NONE
#property indicator_type7   DRAW_NONE
#property indicator_type8   DRAW_NONE
#property indicator_type9   DRAW_NONE
#property indicator_type10  DRAW_NONE
#property indicator_type11  DRAW_NONE
#property indicator_type12  DRAW_NONE
#property indicator_type13  DRAW_NONE
#property indicator_type14  DRAW_NONE
#property indicator_type15  DRAW_NONE
#property indicator_type16  DRAW_NONE
#property indicator_type17  DRAW_NONE
#property indicator_type18  DRAW_NONE
#property indicator_type19  DRAW_NONE
#property indicator_type20  DRAW_NONE
#property indicator_type21  DRAW_NONE
#property indicator_type22  DRAW_NONE
#property indicator_type23  DRAW_NONE
#property indicator_type24  DRAW_NONE

#include <Arrays\ArrayObj.mqh>

//--- Enums
enum ENUM_CALC_MODE
  {
   CALC_MODE_CURRENT, // Current Timeframe
   CALC_MODE_AUTO,    // Auto (Higher TF)
   CALC_MODE_FIXED    // Fixed Timeframe
  };

enum ENUM_LABEL_SIZE
  {
   SIZE_TINY,
   SIZE_SMALL,
   SIZE_NORMAL,
   SIZE_LARGE
  };

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int InpMaxDaysBack = 365; // Max Days to Calculate (Performance)

//--- Calculation Settings
input string grp_calc = "=== Calculation Settings ===";
input ENUM_CALC_MODE InpCalcMode = CALC_MODE_CURRENT; // Calculation Mode
input ENUM_TIMEFRAMES InpFixedTF = PERIOD_D1; // Fixed Timeframe

//--- Visibility Rules (HTF POIs Visible Down To...)
input string grp_vis = "=== HTF Visibility Limits ===";
input ENUM_TIMEFRAMES InpVisM = PERIOD_D1; // Monthly POIs Visible Down To
input ENUM_TIMEFRAMES InpVisW = PERIOD_H4; // Weekly POIs Visible Down To
input ENUM_TIMEFRAMES InpVisD = PERIOD_H1; // Daily POIs Visible Down To
input ENUM_TIMEFRAMES InpVis4H = PERIOD_D1; // 4H POIs Visible Down To (Hidden on 4H if set to D1)
input ENUM_TIMEFRAMES InpVis1H = PERIOD_H1; // 1H POIs Visible Down To
input ENUM_TIMEFRAMES InpVis30m = PERIOD_M15; // 30m POIs Visible Down To
input ENUM_TIMEFRAMES InpVis15m = PERIOD_M5; // 15m POIs Visible Down To

//--- Style & Colors
input string grp_style = "=== Style & Colors (RJ & Swings) ===";
input bool InpShowRJ = true; // Show Rejection Blocks (RJ)
input color InpRJColorBear = clrPurple; // RJ Bearish Color
input color InpRJColorBull = clrOrange; // RJ Bullish Color

input bool InpShowMtfSwings = true; // Show MTF Swings
input color InpMtfSwingColorHigh = clrRed; // Swing High Color
input color InpMtfSwingColorLow = clrGreen; // Swing Low Color

//--- Mitigation Settings
input string grp_delay = "=== Mitigation Settings ===";
input int InpMitigationDelay = 0; // Mitigation Delay (HTF Bars)
input color InpMitigationColor = clrGray; // Mitigated Line Color

//--- Current Structure (Active)
input string grp_main = "=== Current Structure (Active) ===";
input ENUM_TIMEFRAMES InpMshMslMin = PERIOD_H1; // Min Visibility
input ENUM_TIMEFRAMES InpMshMslMax = PERIOD_MN1; // Max Visibility
input color InpMainColorHigh = clrRed; // Active msH Color
input color InpMainColorLow = clrGreen; // Active msL Color
input int InpMainWidth = 2; // Active Line Width

input string grp_hist = "=== Historical Structure ===";
input bool InpShowHist = true; // Show History
input color InpHistColorHigh = clrGray; // History msH
input color InpHistColorLow = clrGray; // History msL
input int InpHistWidth = 1; // Width
input ENUM_LINE_STYLE InpHistStyle = STYLE_DOT; // Style

input string grp_minor = "=== Minor Structure Swings ===";
input bool InpShowMinorSwings = false; // Show Minor Swings
input ENUM_TIMEFRAMES InpMinorMin = PERIOD_H1; // Min Visibility
input ENUM_TIMEFRAMES InpMinorMax = PERIOD_MN1; // Max Visibility
input color InpMinorColorHigh = clrRed; // Minor High
input color InpMinorColorLow = clrGreen; // Minor Low
input ENUM_LINE_STYLE InpMinorStyle = STYLE_DOT; // Style
input int InpMinorWidth = 1; // Width

input string grp_raid = "=== Raid Candles ===";
input color InpRaidColorBear = clrYellow; // Bearish Raid
input color InpRaidColorBull = clrAqua; // Bullish Raid

//--- Extra: Weekly/Daily
input string grp_weekly = "=== EXTRA: Weekly High/Low ===";
input color InpPwhColor = clrGreen; // Previous Week High Color
input color InpPwlColor = clrRed; // Previous Week Low Color

input string grp_daily = "=== EXTRA: Daily High/Low ===";
input color InpYhColor = clrBlue; // Previous Day High Color
input color InpYlColor = clrOrange; // Previous Day Low Color

input string grp_common = "=== EXTRA: Common Settings ===";
input int InpLineWidthExtra = 1; // Line Width
input ENUM_LABEL_SIZE InpTextSizeExtra = SIZE_SMALL; // Label Size

//+------------------------------------------------------------------+
//| Classes & Structures                                             |
//+------------------------------------------------------------------+
class CStructureObj : public CObject
  {
public:
   string            m_line_name;
   string            m_label_name;
   double            m_price;
   bool              m_is_bearish; // or isHigh for swings
   int               m_mitigated_count;
   string            m_tf_name;
   double            m_tf_ratio;
   bool              m_visible;

   CStructureObj() : m_price(0), m_is_bearish(false), m_mitigated_count(-1), m_tf_ratio(1.0), m_visible(true) {}

   ~CStructureObj()
     {
      if(ObjectFind(0, m_line_name) >= 0) ObjectDelete(0, m_line_name);
      if(ObjectFind(0, m_label_name) >= 0) ObjectDelete(0, m_label_name);
     }
  };

class CRJO : public CStructureObj
  {
public:
   CRJO(string ln, string lb, double p, bool bear, int cnt, string tf, double ratio, bool vis)
     {
      m_line_name = ln;
      m_label_name = lb;
      m_price = p;
      m_is_bearish = bear;
      m_mitigated_count = cnt;
      m_tf_name = tf;
      m_tf_ratio = ratio;
      m_visible = vis;
     }
  };

class CMtfSwingObj : public CStructureObj
  {
public:
   CMtfSwingObj(string ln, string lb, double p, bool high, int cnt, string tf, double ratio, bool vis)
     {
      m_line_name = ln;
      m_label_name = lb;
      m_price = p;
      m_is_bearish = high;
      m_mitigated_count = cnt;
      m_tf_name = tf;
      m_tf_ratio = ratio;
      m_visible = vis;
     }
  };

class CStructureLine : public CStructureObj
  {
public:
   CStructureLine(string ln, string lb, double p, bool high, int cnt)
     {
      m_line_name = ln;
      m_label_name = lb;
      m_price = p;
      m_is_bearish = high;
      m_mitigated_count = cnt;
      m_tf_ratio = 1.0;
     }
  };

class CMinorSwingObj : public CStructureObj
  {
public:
   CMinorSwingObj(string ln, string lb, double p, bool high, int cnt, double ratio)
     {
      m_line_name = ln;
      m_label_name = lb;
      m_price = p;
      m_is_bearish = high;
      m_mitigated_count = cnt;
      m_tf_ratio = ratio;
     }
  };

//+------------------------------------------------------------------+
//| Global Variables & State                                         |
//+------------------------------------------------------------------+
CArrayObj ListActiveRJs;
CArrayObj ListActiveMtfSwings;
CArrayObj ListHistoryStructures;
CArrayObj ListActiveMinorSwings;

double g_rangeHighPrice = 0.0;
datetime g_rangeHighTime = 0;
string g_lineHigh = "";
string g_labelHigh = "";

double g_rangeLowPrice = 0.0;
datetime g_rangeLowTime = 0;
string g_lineLow = "";
string g_labelLow = "";

double g_lastKnownSwingHighPrice = 0.0;
datetime g_lastKnownSwingHighTime = 0;
double g_lastKnownSwingLowPrice = 0.0;
datetime g_lastKnownSwingLowTime = 0;

int g_state = 0;

struct StateBuffer
  {
   double            h[3];
   double            l[3];
   double            c[3];
   double            o[3];
   datetime          t[3];
  };

StateBuffer g_buf_Local;
StateBuffer g_buf_15m;
StateBuffer g_buf_30m;
StateBuffer g_buf_1H;
StateBuffer g_buf_4H;
StateBuffer g_buf_D;
StateBuffer g_buf_W;
StateBuffer g_buf_M;

string g_pwhLine, g_pwlLine, g_pwhLabel, g_pwlLabel;
string g_yhLine, g_ylLine, g_yhLabel, g_ylLabel;

//+------------------------------------------------------------------+
//| Buffers                                                          |
//+------------------------------------------------------------------+
double BufferRJ_W_BearHunted[];
double BufferRJ_W_BullHunted[];
double BufferSw_W_BearHunted[];
double BufferSw_W_BullHunted[];
double BufferPWH_Hunted[];
double BufferPWL_Hunted[];
double BufferRJ_D_BearHunted[];
double BufferRJ_D_BullHunted[];
double BufferSw_D_BearHunted[];
double BufferSw_D_BullHunted[];
double BufferYH_Hunted[];
double BufferYL_Hunted[];
double BufferRJ_4H_BearHunted[];
double BufferRJ_4H_BullHunted[];
double BufferSw_4H_BearHunted[];
double BufferSw_4H_BullHunted[];
double BufferSw_1H_BearHunted[];
double BufferSw_1H_BullHunted[];
double BufferSw_30m_BearHunted[];
double BufferSw_30m_BullHunted[];
double BufferSw_15m_BearHunted[];
double BufferSw_15m_BullHunted[];
double BufferRaid_4H_Bear[];
double BufferRaid_4H_Bull[];

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+

string GetTimeframeName(ENUM_TIMEFRAMES tf)
  {
   if(tf == PERIOD_D1) return "D";
   if(tf == PERIOD_W1) return "W";
   if(tf == PERIOD_MN1) return "M";
   if(tf == PERIOD_H4) return "4h";
   if(tf == PERIOD_H1) return "1h";
   if(tf == PERIOD_M30) return "30m";
   if(tf == PERIOD_M15) return "15m";
   return EnumToString(tf);
  }

bool IsVisible(ENUM_TIMEFRAMES minTf, ENUM_TIMEFRAMES maxTf)
  {
   int currentSec = PeriodSeconds(PERIOD_CURRENT);
   int minSec = PeriodSeconds(minTf);
   int maxSec = PeriodSeconds(maxTf);
   return (currentSec >= minSec && currentSec <= maxSec);
  }

void CreateLine(string name, datetime t1, double p1, datetime t2, double p2, color clr, int width, ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
     }
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
     }

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

void CreateLabel(string name, datetime t, double p, string text, color clr, ENUM_LABEL_SIZE size, int anchor)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_TEXT, 0, t, p);
     }
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, t);
      ObjectSetDouble(0, name, OBJPROP_PRICE, p);
     }

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);

   int fontSize = 8;
   if(size == SIZE_TINY) fontSize = 6;
   if(size == SIZE_SMALL) fontSize = 8;
   if(size == SIZE_NORMAL) fontSize = 10;
   if(size == SIZE_LARGE) fontSize = 12;

   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
  }

void UpdateLineX2(string name, datetime t2)
  {
   if(ObjectFind(0, name) >= 0)
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
     }
  }

void UpdateLabelX(string name, datetime t)
  {
   if(ObjectFind(0, name) >= 0)
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, t);
     }
  }

void DeleteObj(string name)
  {
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
  }

//+------------------------------------------------------------------+
//| Core Logic: MTF Management                                       |
//+------------------------------------------------------------------+
void ManageMTFObjects(string sym, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES limitTf, datetime currTime,
                      StateBuffer &buf, bool forceCalc = false)
  {
   // Helper to get Current HTF Time
   int shift = iBarShift(sym, tf, currTime, false);
   datetime thisBarTime = iTime(sym, tf, shift);

   if(thisBarTime != buf.t[2] && buf.t[2] != 0) // Change detected (and not first run)
     {
      int prevShift = shift + 1;
      datetime prevTime = iTime(sym, tf, prevShift);

      if(prevTime != buf.t[2])
        {
         // New completed bar detected
         // Shift buffer
         buf.h[0] = buf.h[1]; buf.h[1] = buf.h[2];
         buf.l[0] = buf.l[1]; buf.l[1] = buf.l[2];
         buf.o[0] = buf.o[1]; buf.o[1] = buf.o[2];
         buf.c[0] = buf.c[1]; buf.c[1] = buf.c[2];
         buf.t[0] = buf.t[1]; buf.t[1] = buf.t[2];

         // Set new values (Previous Completed Bar)
         buf.h[2] = iHigh(sym, tf, prevShift);
         buf.l[2] = iLow(sym, tf, prevShift);
         buf.o[2] = iOpen(sym, tf, prevShift);
         buf.c[2] = iClose(sym, tf, prevShift);
         buf.t[2] = prevTime;

         // Check Logic
         if(buf.t[0] != 0)
           {
            double h0 = buf.h[2];
            double h1 = buf.h[1];
            double h2 = buf.h[0];

            double l0 = buf.l[2];
            double l1 = buf.l[1];
            double l2 = buf.l[0];

            datetime t1 = buf.t[1];
            datetime t0 = buf.t[2];

            bool swH = h1 > h0 && h1 > h2;
            bool swL = l1 < l0 && l1 < l2;

            string tfName = GetTimeframeName(tf);

            // RJ Logic
            bool allowRJ = PeriodSeconds(tf) >= 14400; // >= 4H
            bool isVisible = IsVisible(tf, limitTf);

            double ratio = (double)PeriodSeconds(tf) / (double)PeriodSeconds(PERIOD_CURRENT);

            if(swH)
              {
               if(InpShowRJ && allowRJ)
                 {
                  double maxBody0 = MathMax(buf.o[2], buf.c[2]);
                  double maxBody1 = MathMax(buf.o[1], buf.c[1]);
                  double maxBody2 = MathMax(buf.o[0], buf.c[0]);
                  double maxBody = MathMax(maxBody0, MathMax(maxBody1, maxBody2));

                  string nameLn = "RJ-Bear-" + tfName + "-" + IntegerToString((long)t1);
                  string nameLb = "RJ-Lb-Bear-" + tfName + "-" + IntegerToString((long)t1);

                  if(isVisible)
                    {
                     CreateLine(nameLn, t1, maxBody, t0, maxBody, InpRJColorBear, 1, STYLE_SOLID);
                     CreateLabel(nameLb, t0, maxBody, "RJ-"+tfName, InpRJColorBear, SIZE_TINY, 0);
                    }

                  ListActiveRJs.Add(new CRJO(nameLn, nameLb, maxBody, true, -1, GetTimeframeName(tf), ratio, isVisible));
                 }

               if(InpShowMtfSwings)
                 {
                  string nameLn = "SwH-" + tfName + "-" + IntegerToString((long)t1);
                  string nameLb = "SwH-Lb-" + tfName + "-" + IntegerToString((long)t1);

                  if(isVisible)
                    {
                     CreateLine(nameLn, t1, h1, t0, h1, InpMtfSwingColorHigh, InpMinorWidth, InpMinorStyle);
                     CreateLabel(nameLb, t0, h1, "SwH-"+tfName, InpMtfSwingColorHigh, SIZE_TINY, 0);
                    }

                  ListActiveMtfSwings.Add(new CMtfSwingObj(nameLn, nameLb, h1, true, -1, GetTimeframeName(tf), ratio, isVisible));
                 }
              }

            if(swL)
              {
               if(InpShowRJ && allowRJ)
                 {
                  double minBody0 = MathMin(buf.o[2], buf.c[2]);
                  double minBody1 = MathMin(buf.o[1], buf.c[1]);
                  double minBody2 = MathMin(buf.o[0], buf.c[0]);
                  double minBody = MathMin(minBody0, MathMin(minBody1, minBody2));

                  string nameLn = "RJ-Bull-" + tfName + "-" + IntegerToString((long)t1);
                  string nameLb = "RJ-Lb-Bull-" + tfName + "-" + IntegerToString((long)t1);

                  if(isVisible)
                    {
                     CreateLine(nameLn, t1, minBody, t0, minBody, InpRJColorBull, 1, STYLE_SOLID);
                     CreateLabel(nameLb, t0, minBody, "RJ-"+tfName, InpRJColorBull, SIZE_TINY, 0);
                    }

                  ListActiveRJs.Add(new CRJO(nameLn, nameLb, minBody, false, -1, GetTimeframeName(tf), ratio, isVisible));
                 }

               if(InpShowMtfSwings)
                 {
                  string nameLn = "SwL-" + tfName + "-" + IntegerToString((long)t1);
                  string nameLb = "SwL-Lb-" + tfName + "-" + IntegerToString((long)t1);

                  if(isVisible)
                    {
                     CreateLine(nameLn, t1, l1, t0, l1, InpMtfSwingColorLow, InpMinorWidth, InpMinorStyle);
                     CreateLabel(nameLb, t0, l1, "SwL-"+tfName, InpMtfSwingColorLow, SIZE_TINY, 0);
                    }

                  ListActiveMtfSwings.Add(new CMtfSwingObj(nameLn, nameLb, l1, false, -1, GetTimeframeName(tf), ratio, isVisible));
                 }
              }
           }
        }
     }
   else if(buf.t[2] == 0) // Initialization (First run)
     {
      int shiftInit = iBarShift(sym, tf, currTime, false);
      if(shiftInit >= 0)
        {
         buf.t[2] = iTime(sym, tf, shiftInit+1); // Store PREVIOUS bar time to start tracking
        }
     }
  }

//+------------------------------------------------------------------+
//| Core Logic: Mitigation Loop                                      |
//+------------------------------------------------------------------+
void ProcessMitigation(double high, double low, datetime t, bool isConfirmed)
  {
   // 1. RJ Mitigation
   for(int i = ListActiveRJs.Total() - 1; i >= 0; i--)
     {
      CRJO *objRJ = (CRJO*)ListActiveRJs.At(i);
      if(CheckPointer(objRJ) == POINTER_INVALID) continue;

      bool isTouched = false;
      if(objRJ.m_is_bearish)
        {
         if(high >= objRJ.m_price) isTouched = true;
        }
      else
        {
         if(low <= objRJ.m_price) isTouched = true;
        }

      // Immediate State Update
      if(objRJ.m_mitigated_count == -1 && isTouched)
        {
         objRJ.m_mitigated_count = 0;
        }

      bool readyToDelete = false;
      if(objRJ.m_mitigated_count != -1)
        {
         double scaledDelay = InpMitigationDelay * objRJ.m_tf_ratio;
         if(objRJ.m_mitigated_count >= scaledDelay)
           {
            readyToDelete = true;
           }
         else
           {
            if(isConfirmed) objRJ.m_mitigated_count++;
           }
        }

      if(readyToDelete)
        {
         ListActiveRJs.Delete(i);
        }
      else
        {
         UpdateLineX2(objRJ->m_line_name, t);
         UpdateLabelX(objRJ->m_label_name, t);

         color finalColor = objRJ->m_is_bearish ? InpRJColorBear : InpRJColorBull;
         if(objRJ->m_mitigated_count != -1) finalColor = InpMitigationColor;

         if(!objRJ->m_visible) finalColor = clrNone;

         ObjectSetInteger(0, objRJ->m_line_name, OBJPROP_COLOR, finalColor);
         ObjectSetInteger(0, objRJ->m_label_name, OBJPROP_COLOR, finalColor);
        }
     }
   // 2. MTF Swings Mitigation
   for(int i = ListActiveMtfSwings.Total() - 1; i >= 0; i--)
     {
      CMtfSwingObj *objSw = (CMtfSwingObj*)ListActiveMtfSwings.At(i);
      if(CheckPointer(objSw) == POINTER_INVALID) continue;

      bool isTouched = false;
      if(objSw->m_is_bearish) // High
         if(high >= objSw->m_price) isTouched = true;
      else
         if(low <= objSw->m_price) isTouched = true;

      if(objSw->m_mitigated_count == -1 && isTouched) objSw->m_mitigated_count = 0;

      bool readyToDelete = false;
      if(objSw->m_mitigated_count != -1)
        {
         double scaledDelay = InpMitigationDelay * objSw->m_tf_ratio;
         if(objSw->m_mitigated_count >= scaledDelay) readyToDelete = true;
         else if(isConfirmed) objSw->m_mitigated_count++;
        }

      if(readyToDelete) ListActiveMtfSwings.Delete(i);
      else
        {
         UpdateLineX2(objSw->m_line_name, t);
         UpdateLabelX(objSw->m_label_name, t);

         color finalColor = objSw->m_is_bearish ? InpMtfSwingColorHigh : InpMtfSwingColorLow;
         if(objSw->m_mitigated_count != -1) finalColor = InpMitigationColor;
         if(!objSw->m_visible) finalColor = clrNone;

         ObjectSetInteger(0, objSw->m_line_name, OBJPROP_COLOR, finalColor);
         ObjectSetInteger(0, objSw->m_label_name, OBJPROP_COLOR, finalColor);
        }
     }
   // 3. Local/Structural Minor Swings
   for(int i = ListActiveMinorSwings.Total() - 1; i >= 0; i--)
     {
      CMinorSwingObj *item = (CMinorSwingObj*)ListActiveMinorSwings.At(i);
      if(CheckPointer(item) == POINTER_INVALID) continue;

      bool isTouched = false;
      if(item->m_is_bearish)
         if(high >= item->m_price) isTouched = true;
      else
         if(low <= item->m_price) isTouched = true;

      if(item->m_mitigated_count == -1 && isTouched) item->m_mitigated_count = 0;

      bool readyToDelete = false;
      if(item->m_mitigated_count != -1)
        {
         double scaledDelay = InpMitigationDelay * item->m_tf_ratio;
         if(item->m_mitigated_count >= scaledDelay) readyToDelete = true;
         else if(isConfirmed) item->m_mitigated_count++;
        }

      if(readyToDelete) ListActiveMinorSwings.Delete(i);
      else
        {
         UpdateLineX2(item->m_line_name, t);
         UpdateLabelX(item->m_label_name, t);

         color finalColor = item->m_is_bearish ? InpMinorColorHigh : InpMinorColorLow;
         if(item->m_mitigated_count != -1) finalColor = InpMitigationColor;

         ObjectSetInteger(0, item->m_line_name, OBJPROP_COLOR, finalColor);
         ObjectSetInteger(0, item->m_label_name, OBJPROP_COLOR, finalColor);
        }
     }
   // 4. Historical Structures (Main BOS/Structure Lines)
   for(int i = ListHistoryStructures.Total() - 1; i >= 0; i--)
     {
      CStructureLine *item = (CStructureLine*)ListHistoryStructures.At(i);
      if(CheckPointer(item) == POINTER_INVALID) continue;

      bool isTouched = false;
      if(item->m_is_bearish) // High
         if(high >= item->m_price) isTouched = true;
      else
         if(low <= item->m_price) isTouched = true;

      if(item->m_mitigated_count == -1 && isTouched) item->m_mitigated_count = 0;

      bool readyToDelete = false;
      if(item->m_mitigated_count != -1)
        {
         double scaledDelay = InpMitigationDelay * item->m_tf_ratio;
         if(item->m_mitigated_count >= scaledDelay) readyToDelete = true;
         else if(isConfirmed) item->m_mitigated_count++;
        }

      if(readyToDelete) ListHistoryStructures.Delete(i);
      else
        {
         UpdateLineX2(item->m_line_name, t);
         UpdateLabelX(item->m_label_name, t);

         color finalColor = item->m_is_bearish ? InpHistColorHigh : InpHistColorLow;
         if(item->m_mitigated_count != -1) finalColor = InpMitigationColor;
         if(!InpShowHist) finalColor = clrNone;

         ObjectSetInteger(0, item->m_line_name, OBJPROP_COLOR, finalColor);
         ObjectSetInteger(0, item->m_label_name, OBJPROP_COLOR, finalColor);
        }
     }
  }

const int F_ALERT_1 = 1;

//+------------------------------------------------------------------+
//| Core Logic: Main Structure (State Machine)                       |
//+------------------------------------------------------------------+
void ProcessMainStructure(int i, const double &high_array[], const double &low_array[], const double &close_array[], const double &open_array[], const datetime &time_array[], double targetRatio, bool isLive)
  {
   // Push to buffer
   g_buf_Local.h[0] = g_buf_Local.h[1]; g_buf_Local.h[1] = g_buf_Local.h[2];
   g_buf_Local.l[0] = g_buf_Local.l[1]; g_buf_Local.l[1] = g_buf_Local.l[2];
   g_buf_Local.c[0] = g_buf_Local.c[1]; g_buf_Local.c[1] = g_buf_Local.c[2];
   g_buf_Local.o[0] = g_buf_Local.o[1]; g_buf_Local.o[1] = g_buf_Local.o[2];
   g_buf_Local.t[0] = g_buf_Local.t[1]; g_buf_Local.t[1] = g_buf_Local.t[2];

   // Push New
   g_buf_Local.h[2] = high_array[i];
   g_buf_Local.l[2] = low_array[i];
   g_buf_Local.c[2] = close_array[i];
   g_buf_Local.o[2] = open_array[i];
   g_buf_Local.t[2] = time_array[i];

   if(g_buf_Local.t[0] == 0) return;

   double h0 = g_buf_Local.h[2];
   double h1 = g_buf_Local.h[1];
   double h2 = g_buf_Local.h[0];
   double l0 = g_buf_Local.l[2];
   double l1 = g_buf_Local.l[1];
   double l2 = g_buf_Local.l[0];
   datetime t0 = g_buf_Local.t[2];
   datetime t1 = g_buf_Local.t[1];

   bool swH = h1 > h0 && h1 > h2;
   bool swL = l1 < l0 && l1 < l2;

   bool visibleMain = IsVisible(InpMshMslMin, InpMshMslMax);
   // bool visibleHist = InpShowHist; // Unused
   bool visibleMinor = InpShowMinorSwings && IsVisible(InpMinorMin, InpMinorMax);

   if(swH)
     {
      g_lastKnownSwingHighPrice = h1;
      g_lastKnownSwingHighTime = t1;
      if(visibleMinor)
        {
         string lnName = "MinorH-" + IntegerToString((long)t1);
         string lbName = "MinorH-Lb-" + IntegerToString((long)t1);
         CreateLine(lnName, t1, h1, t0, h1, InpMinorColorHigh, InpMinorWidth, InpMinorStyle);
         CreateLabel(lbName, t0, h1, "Sw-H", InpMinorColorHigh, SIZE_TINY, 0);
         ListActiveMinorSwings.Add(new CMinorSwingObj(lnName, lbName, h1, true, -1, targetRatio));
        }
     }

   if(swL)
     {
      g_lastKnownSwingLowPrice = l1;
      g_lastKnownSwingLowTime = t1;
      if(visibleMinor)
        {
         string lnName = "MinorL-" + IntegerToString((long)t1);
         string lbName = "MinorL-Lb-" + IntegerToString((long)t1);
         CreateLine(lnName, t1, l1, t0, l1, InpMinorColorLow, InpMinorWidth, InpMinorStyle);
         CreateLabel(lbName, t0, l1, "Sw-L", InpMinorColorLow, SIZE_TINY, 0);
         ListActiveMinorSwings.Add(new CMinorSwingObj(lnName, lbName, l1, false, -1, targetRatio));
        }
     }

   // --- State Machine ---
   // color cMainHigh = visibleMain ? InpMainColorHigh : clrNone; // Unused
   // color cMainLow = visibleMain ? InpMainColorLow : clrNone; // Unused

   double closePrice = g_buf_Local.c[2];
   // double highPrice = g_buf_Local.h[2]; // Unused
   // double lowPrice = g_buf_Local.l[2]; // Unused

   if(g_state == 0)
     {
      if(g_rangeHighPrice == 0 && g_lastKnownSwingHighPrice != 0)
        {
         g_rangeHighPrice = g_lastKnownSwingHighPrice;
         g_rangeHighTime = g_lastKnownSwingHighTime;

         g_lineHigh = "MainH-Active";
         g_labelHigh = "MainH-Lb-Active";
         CreateLine(g_lineHigh, g_rangeHighTime, g_rangeHighPrice, t0, g_rangeHighPrice, InpMainColorHigh, InpMainWidth, STYLE_SOLID);
         CreateLabel(g_labelHigh, g_rangeHighTime, g_rangeHighPrice, "H", InpMainColorHigh, SIZE_TINY, 0);
         ObjectSetInteger(0, g_lineHigh, OBJPROP_RAY_RIGHT, true);
        }
      if(g_rangeLowPrice == 0 && g_lastKnownSwingLowPrice != 0)
        {
         g_rangeLowPrice = g_lastKnownSwingLowPrice;
         g_rangeLowTime = g_lastKnownSwingLowTime;
         g_lineLow = "MainL-Active";
         g_labelLow = "MainL-Lb-Active";
         CreateLine(g_lineLow, g_rangeLowTime, g_rangeLowPrice, t0, g_rangeLowPrice, InpMainColorLow, InpMainWidth, STYLE_SOLID);
         CreateLabel(g_labelLow, g_rangeLowTime, g_rangeLowPrice, "L", InpMainColorLow, SIZE_TINY, 0);
         ObjectSetInteger(0, g_lineLow, OBJPROP_RAY_RIGHT, true);
        }
      if(g_rangeHighPrice != 0 && g_rangeLowPrice != 0) g_state = 1;
     }
   else if(g_state == 1)
     {
      UpdateLineX2(g_lineHigh, t0);
      UpdateLineX2(g_lineLow, t0);

      // Check BOS
      if(closePrice > g_rangeHighPrice)
        {
         // Bullish BOS
         datetime midTime = (g_rangeHighTime + t0) / 2;
         string bosLbName = "BOS-Bull-" + IntegerToString((long)t0);
         string bosLnName = "BOS-Bull-Ln-" + IntegerToString((long)t0);

         if(visibleMain)
           {
            CreateLabel(bosLbName, midTime, g_rangeHighPrice, "BOS", clrBlue, SIZE_SMALL, 0);
            CreateLine(bosLnName, g_rangeHighTime, g_rangeHighPrice, t0, g_rangeHighPrice, clrBlue, 1, STYLE_DASH);
           }

         ObjectSetInteger(0, g_lineHigh, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, g_lineHigh, OBJPROP_TIME, 1, t0);

         string histHName = "HistH-" + IntegerToString((long)g_rangeHighTime);
         string histHLbName = "HistH-Lb-" + IntegerToString((long)g_rangeHighTime);
         ObjectSetString(0, g_lineHigh, OBJPROP_NAME, histHName);
         ObjectSetString(0, g_labelHigh, OBJPROP_NAME, histHLbName);

         ListHistoryStructures.Add(new CStructureLine(histHName, histHLbName, g_rangeHighPrice, true, 0)); // Mitigated immediately
         if(isLive) Alert("Bullish BOS");

         ObjectSetInteger(0, g_lineLow, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, g_lineLow, OBJPROP_TIME, 1, t0);
         string histLName = "HistL-" + IntegerToString((long)g_rangeLowTime);
         string histLLbName = "HistL-Lb-" + IntegerToString((long)g_rangeLowTime);
         ObjectSetString(0, g_lineLow, OBJPROP_NAME, histLName);
         ObjectSetString(0, g_labelLow, OBJPROP_NAME, histLLbName);

         ListHistoryStructures.Add(new CStructureLine(histLName, histLLbName, g_rangeLowPrice, false, -1));

         g_rangeLowPrice = g_lastKnownSwingLowPrice;
         g_rangeLowTime = g_lastKnownSwingLowTime;

         g_lineLow = "MainL-Active";
         g_labelLow = "MainL-Lb-Active";
         if(visibleMain)
           {
            CreateLine(g_lineLow, g_rangeLowTime, g_rangeLowPrice, t0, g_rangeLowPrice, InpMainColorLow, InpMainWidth, STYLE_SOLID);
            CreateLabel(g_labelLow, g_rangeLowTime, g_rangeLowPrice, "msL", InpMainColorLow, SIZE_TINY, 0);
            ObjectSetInteger(0, g_lineLow, OBJPROP_RAY_RIGHT, true);
           }

         g_rangeHighPrice = 0; g_rangeHighTime = 0;
         g_state = 2;
        }
      else if(closePrice < g_rangeLowPrice)
        {
         // Bearish BOS
         datetime midTime = (g_rangeLowTime + t0) / 2;
         string bosLbName = "BOS-Bear-" + IntegerToString((long)t0);
         string bosLnName = "BOS-Bear-Ln-" + IntegerToString((long)t0);

         if(visibleMain)
           {
            CreateLabel(bosLbName, midTime, g_rangeLowPrice, "BOS", clrOrange, SIZE_SMALL, 0);
            CreateLine(bosLnName, g_rangeLowTime, g_rangeLowPrice, t0, g_rangeLowPrice, clrOrange, 1, STYLE_DASH);
           }

         ObjectSetInteger(0, g_lineLow, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, g_lineLow, OBJPROP_TIME, 1, t0);
         string histLName = "HistL-" + IntegerToString((long)g_rangeLowTime);
         string histLLbName = "HistL-Lb-" + IntegerToString((long)g_rangeLowTime);
         ObjectSetString(0, g_lineLow, OBJPROP_NAME, histLName);
         ObjectSetString(0, g_labelLow, OBJPROP_NAME, histLLbName);
         ListHistoryStructures.Add(new CStructureLine(histLName, histLLbName, g_rangeLowPrice, false, 0));
         if(isLive) Alert("Bearish BOS");

         ObjectSetInteger(0, g_lineHigh, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, g_lineHigh, OBJPROP_TIME, 1, t0);
         string histHName = "HistH-" + IntegerToString((long)g_rangeHighTime);
         string histHLbName = "HistH-Lb-" + IntegerToString((long)g_rangeHighTime);
         ObjectSetString(0, g_lineHigh, OBJPROP_NAME, histHName);
         ObjectSetString(0, g_labelHigh, OBJPROP_NAME, histHLbName);
         ListHistoryStructures.Add(new CStructureLine(histHName, histHLbName, g_rangeHighPrice, true, -1));

         g_rangeHighPrice = g_lastKnownSwingHighPrice;
         g_rangeHighTime = g_lastKnownSwingHighTime;

         g_lineHigh = "MainH-Active";
         g_labelHigh = "MainH-Lb-Active";
         if(visibleMain)
           {
            CreateLine(g_lineHigh, g_rangeHighTime, g_rangeHighPrice, t0, g_rangeHighPrice, InpMainColorLow, InpMainWidth, STYLE_SOLID);
            CreateLabel(g_labelHigh, g_rangeHighTime, g_rangeHighPrice, "msH", InpMainColorHigh, SIZE_TINY, 0);
            ObjectSetInteger(0, g_lineHigh, OBJPROP_RAY_RIGHT, true);
           }

         g_rangeLowPrice = 0; g_rangeLowTime = 0;
         g_state = 3;
        }
     }
   else if(g_state == 2)
     {
      UpdateLineX2(g_lineLow, t0);
      if(swH && h1 > g_rangeLowPrice)
        {
         g_rangeHighPrice = h1;
         g_rangeHighTime = t1;

         g_lineHigh = "MainH-Active";
         g_labelHigh = "MainH-Lb-Active";
         if(visibleMain)
           {
            CreateLine(g_lineHigh, g_rangeHighTime, g_rangeHighPrice, t0, g_rangeHighPrice, InpMainColorLow, InpMainWidth, STYLE_SOLID);
            CreateLabel(g_labelHigh, g_rangeHighTime, g_rangeHighPrice, "H", InpMainColorHigh, SIZE_TINY, 0);
            ObjectSetInteger(0, g_lineHigh, OBJPROP_RAY_RIGHT, true);
           }
         g_state = 1;
        }
      if(closePrice < g_rangeLowPrice)
        {
         DeleteObj(g_lineLow);
         DeleteObj(g_labelLow);
         g_state = 0;
         g_rangeLowPrice = 0;
        }
     }
   else if(g_state == 3)
     {
      UpdateLineX2(g_lineHigh, t0);
      if(swL && l1 < g_rangeHighPrice)
        {
         g_rangeLowPrice = l1;
         g_rangeLowTime = t1;

         g_lineLow = "MainL-Active";
         g_labelLow = "MainL-Lb-Active";
         if(visibleMain)
           {
            CreateLine(g_lineLow, g_rangeLowTime, g_rangeLowPrice, t0, g_rangeLowPrice, InpMainColorLow, InpMainWidth, STYLE_SOLID);
            CreateLabel(g_labelLow, g_rangeLowTime, g_rangeLowPrice, "L", InpMainColorLow, SIZE_TINY, 0);
            ObjectSetInteger(0, g_lineLow, OBJPROP_RAY_RIGHT, true);
           }
         g_state = 1;
        }
      if(closePrice > g_rangeHighPrice)
        {
         DeleteObj(g_lineHigh);
         DeleteObj(g_labelHigh);
         g_state = 0;
         g_rangeHighPrice = 0;
        }
     }
  }

void Alert(string msg)
  {
   ::Alert(msg);
  }

//+------------------------------------------------------------------+
//| Core Logic: Extra Levels (PWH/PWL/PDH/PDL)                       |
//+------------------------------------------------------------------+
void DrawExtraLevels(datetime currTime)
  {
   int currentSec = PeriodSeconds(PERIOD_CURRENT);
   int secW = PeriodSeconds(PERIOD_W1);
   int secD = PeriodSeconds(PERIOD_D1);

   int limitW = PeriodSeconds(InpVisW);
   int limitD = PeriodSeconds(InpVisD);

   bool showWeek = (currentSec <= secW && currentSec >= limitW);
   bool showDay = (currentSec <= secD && currentSec >= limitD);

   if(showWeek)
     {
      double pwh = iHigh(Symbol(), PERIOD_W1, 1);
      double pwl = iLow(Symbol(), PERIOD_W1, 1);

      datetime startW = iTime(Symbol(), PERIOD_W1, 0);

      if(currentSec == secW)
        {
         startW = iTime(Symbol(), PERIOD_W1, 1);
        }

      if(pwh != 0 && pwl != 0 && startW > 0)
        {
         g_pwhLine = "Extra-PWH-Line";
         g_pwlLine = "Extra-PWL-Line";
         g_pwhLabel = "Extra-PWH-Label";
         g_pwlLabel = "Extra-PWL-Label";

         CreateLine(g_pwhLine, startW, pwh, currTime, pwh, InpPwhColor, InpLineWidthExtra, STYLE_SOLID);
         CreateLine(g_pwlLine, startW, pwl, currTime, pwl, InpPwlColor, InpLineWidthExtra, STYLE_SOLID);

         CreateLabel(g_pwhLabel, currTime, pwh, "pwH", InpPwhColor, InpTextSizeExtra, 0);
         CreateLabel(g_pwlLabel, currTime, pwl, "pwL", InpPwlColor, InpTextSizeExtra, 0);

         ObjectSetInteger(0, g_pwhLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, g_pwlLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
        }
     }
   else
     {
      DeleteObj(g_pwhLine); DeleteObj(g_pwlLine); DeleteObj(g_pwhLabel); DeleteObj(g_pwlLabel);
     }

   if(showDay)
     {
      double pdh = iHigh(Symbol(), PERIOD_D1, 1);
      double pdl = iLow(Symbol(), PERIOD_D1, 1);

      datetime startD = iTime(Symbol(), PERIOD_D1, 0);

      if(currentSec == secD)
        {
         startD = iTime(Symbol(), PERIOD_D1, 1);
        }

      if(pdh != 0 && pdl != 0 && startD > 0)
        {
         g_yhLine = "Extra-PDH-Line";
         g_ylLine = "Extra-PDL-Line";
         g_yhLabel = "Extra-PDH-Label";
         g_ylLabel = "Extra-PDL-Label";

         CreateLine(g_yhLine, startD, pdh, currTime, pdh, InpYhColor, InpLineWidthExtra, STYLE_SOLID);
         CreateLine(g_ylLine, startD, pdl, currTime, pdl, InpYlColor, InpLineWidthExtra, STYLE_SOLID);

         CreateLabel(g_yhLabel, currTime, pdh, "yH", InpYhColor, InpTextSizeExtra, 0);
         CreateLabel(g_ylLabel, currTime, pdl, "yL", InpYlColor, InpTextSizeExtra, 0);

         ObjectSetInteger(0, g_yhLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, g_ylLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
        }
     }
   else
     {
      DeleteObj(g_yhLine); DeleteObj(g_ylLine); DeleteObj(g_yhLabel); DeleteObj(g_ylLabel);
     }
  }

//+------------------------------------------------------------------+
//| Custom Indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, BufferRJ_W_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(1, BufferRJ_W_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(2, BufferSw_W_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(3, BufferSw_W_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(4, BufferPWH_Hunted, INDICATOR_DATA);
   SetIndexBuffer(5, BufferPWL_Hunted, INDICATOR_DATA);
   SetIndexBuffer(6, BufferRJ_D_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(7, BufferRJ_D_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(8, BufferSw_D_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(9, BufferSw_D_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(10, BufferYH_Hunted, INDICATOR_DATA);
   SetIndexBuffer(11, BufferYL_Hunted, INDICATOR_DATA);
   SetIndexBuffer(12, BufferRJ_4H_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(13, BufferRJ_4H_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(14, BufferSw_4H_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(15, BufferSw_4H_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(16, BufferSw_1H_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(17, BufferSw_1H_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(18, BufferSw_30m_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(19, BufferSw_30m_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(20, BufferSw_15m_BearHunted, INDICATOR_DATA);
   SetIndexBuffer(21, BufferSw_15m_BullHunted, INDICATOR_DATA);
   SetIndexBuffer(22, BufferRaid_4H_Bear, INDICATOR_DATA);
   SetIndexBuffer(23, BufferRaid_4H_Bull, INDICATOR_DATA);

   PlotIndexSetString(0, PLOT_LABEL, "Signal RJ-W Bearish Hunted");
   PlotIndexSetString(1, PLOT_LABEL, "Signal RJ-W Bullish Hunted");
   PlotIndexSetString(2, PLOT_LABEL, "Signal Swing-W Bearish Hunted");
   PlotIndexSetString(3, PLOT_LABEL, "Signal Swing-W Bullish Hunted");
   PlotIndexSetString(4, PLOT_LABEL, "Signal PWH Hunted (Bearish)");
   PlotIndexSetString(5, PLOT_LABEL, "Signal PWL Hunted (Bullish)");
   PlotIndexSetString(6, PLOT_LABEL, "Signal RJ-D Bearish Hunted");
   PlotIndexSetString(7, PLOT_LABEL, "Signal RJ-D Bullish Hunted");
   PlotIndexSetString(8, PLOT_LABEL, "Signal Swing-D Bearish Hunted");
   PlotIndexSetString(9, PLOT_LABEL, "Signal Swing-D Bullish Hunted");
   PlotIndexSetString(10, PLOT_LABEL, "Signal yH Hunted (Bearish)");
   PlotIndexSetString(11, PLOT_LABEL, "Signal yL Hunted (Bullish)");
   PlotIndexSetString(12, PLOT_LABEL, "Signal RJ-4H Bearish Hunted");
   PlotIndexSetString(13, PLOT_LABEL, "Signal RJ-4H Bullish Hunted");
   PlotIndexSetString(14, PLOT_LABEL, "Signal Swing-4H Bearish Hunted");
   PlotIndexSetString(15, PLOT_LABEL, "Signal Swing-4H Bullish Hunted");
   PlotIndexSetString(16, PLOT_LABEL, "Signal Swing-1H Bearish Hunted");
   PlotIndexSetString(17, PLOT_LABEL, "Signal Swing-1H Bullish Hunted");
   PlotIndexSetString(18, PLOT_LABEL, "Signal Swing-30m Bearish Hunted");
   PlotIndexSetString(19, PLOT_LABEL, "Signal Swing-30m Bullish Hunted");
   PlotIndexSetString(20, PLOT_LABEL, "Signal Swing-15m Bearish Hunted");
   PlotIndexSetString(21, PLOT_LABEL, "Signal Swing-15m Bullish Hunted");
   PlotIndexSetString(22, PLOT_LABEL, "Signal Raid-4H Bearish");
   PlotIndexSetString(23, PLOT_LABEL, "Signal Raid-4H Bullish");

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Dashboard Logic                                                  |
//+------------------------------------------------------------------+
void DrawCell(string name, int col, int row, string text, color bg, color txt)
  {
   int cellW = 100;
   int cellH = 20;
   int startX = 10;
   int startY = 30;

   int x = startX + col * cellW;
   int y = startY + row * cellH;

   string bgName = "DashBG_" + IntegerToString(col) + "" + IntegerToString(row);
   string txtName = "DashTxt" + IntegerToString(col) + "_" + IntegerToString(row);

   if(ObjectFind(0, bgName) < 0)
     {
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, cellW);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, cellH);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
     }

   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrNone);

   if(ObjectFind(0, txtName) < 0)
     {
      ObjectCreate(0, txtName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, txtName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, txtName, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, 8);
     }

   ObjectSetInteger(0, txtName, OBJPROP_XDISTANCE, x + cellW/2);
   ObjectSetInteger(0, txtName, OBJPROP_YDISTANCE, y + cellH/2 - 5);
   ObjectSetString(0, txtName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, txtName, OBJPROP_COLOR, txt);
  }

void DrawDashboard(double closePrice)
  {
   struct DashResult
     {
      double            bearDist;
      double            bullDist;
      double            bearPrice;
      double            bullPrice;
      bool              bearHunted;
      bool              bullHunted;
     };

   DashResult resRJ[6];
   DashResult resSw[6];

   for(int k=0; k<6; k++)
     {
      resRJ[k].bearDist=DBL_MAX;
      resRJ[k].bullDist=DBL_MAX;
      resSw[k].bearDist=DBL_MAX;
      resSw[k].bullDist=DBL_MAX;
     }

   // Loop RJs
   for(int i=0; i<ListActiveRJs.Total(); i++)
     {
      CRJO *objRJ = (CRJO*)ListActiveRJs.At(i);
      if(CheckPointer(objRJ) == POINTER_INVALID) continue;

      double dist = MathAbs(closePrice - objRJ->m_price);
      int idx = -1;
      if(objRJ->m_tf_name == "W") idx = 0;
      else if(objRJ->m_tf_name == "D") idx = 1;
      else if(objRJ->m_tf_name == "4h") idx = 2;

      if(idx != -1)
        {
         if(objRJ->m_is_bearish)
           {
            if(dist < resRJ[idx].bearDist) { resRJ[idx].bearDist = dist; resRJ[idx].bearPrice = objRJ->m_price; resRJ[idx].bearHunted = (objRJ->m_mitigated_count!=-1); }
           }
         else
           {
            if(dist < resRJ[idx].bullDist) { resRJ[idx].bullDist = dist; resRJ[idx].bullPrice = objRJ->m_price; resRJ[idx].bullHunted = (objRJ->m_mitigated_count!=-1); }
           }
        }
     }
   // Loop Swings
   for(int i=0; i<ListActiveMtfSwings.Total(); i++)
     {
      CMtfSwingObj *objSw = (CMtfSwingObj*)ListActiveMtfSwings.At(i);
      if(CheckPointer(objSw) == POINTER_INVALID) continue;

      double dist = MathAbs(closePrice - objSw->m_price);
      int idx = -1;
      if(objSw->m_tf_name == "W") idx = 0;
      else if(objSw->m_tf_name == "D") idx = 1;
      else if(objSw->m_tf_name == "4h") idx = 2;
      else if(objSw->m_tf_name == "1h") idx = 3;
      else if(objSw->m_tf_name == "30m") idx = 4;
      else if(objSw->m_tf_name == "15m") idx = 5;

      if(idx != -1)
        {
         if(objSw->m_is_bearish)
           {
            if(dist < resSw[idx].bearDist) { resSw[idx].bearDist = dist; resSw[idx].bearPrice = objSw->m_price; resSw[idx].bearHunted = (objSw->m_mitigated_count!=-1); }
           }
         else
           {
            if(dist < resSw[idx].bullDist) { resSw[idx].bullDist = dist; resSw[idx].bullPrice = objSw->m_price; resSw[idx].bullHunted = (objSw->m_mitigated_count!=-1); }
           }
        }
     }
   // --- Logic for PWH/L & yH/L ---
   double pwh = iHigh(Symbol(), PERIOD_W1, 1);
   double pwl = iLow(Symbol(), PERIOD_W1, 1);
   double currWH = iHigh(Symbol(), PERIOD_W1, 0);
   double currWL = iLow(Symbol(), PERIOD_W1, 0);
   bool pwhHunted = (currWH >= pwh);
   bool pwlHunted = (currWL <= pwl);

   double pdh = iHigh(Symbol(), PERIOD_D1, 1);
   double pdl = iLow(Symbol(), PERIOD_D1, 1);
   double currDH = iHigh(Symbol(), PERIOD_D1, 0);
   double currDL = iLow(Symbol(), PERIOD_D1, 0);
   bool pdhHunted = (currDH >= pdh);
   bool pdlHunted = (currDL <= pdl);

   // --- Logic for 4H Raid ---
   bool raid4HBear = false;
   bool raid4HBull = false;

   double c4 = iClose(Symbol(), PERIOD_H4, 0);
   double h4_curr = iHigh(Symbol(), PERIOD_H4, 0);
   double l4_curr = iLow(Symbol(), PERIOD_H4, 0);

   if(resSw[2].bearDist != DBL_MAX)
     {
      if(h4_curr > resSw[2].bearPrice && c4 < resSw[2].bearPrice) raid4HBear = true;
     }
   if(resSw[2].bullDist != DBL_MAX)
     {
      if(l4_curr < resSw[2].bullPrice && c4 > resSw[2].bullPrice) raid4HBull = true;
     }

   // --- Drawing ---
   int row = 12;
   DrawCell("H_0", 0, row, "Status", C'50,50,255', clrWhite);
   DrawCell("H_1", 1, row, "Bearish Level", C'255,50,50', clrWhite);
   DrawCell("H_2", 2, row, "Bullish Level", C'50,255,50', clrWhite);

   string labels[] = {"Weekly RJ", "Weekly Swing", "Weekly PWH/L", "Daily RJ", "Daily Swing", "Daily yH/L", "4H RJ", "4H Swing", "1H Swing", "30m Swing", "15m Swing", "4H Raid"};

   // 1. Weekly RJ
   row--; // 11
   DrawCell("R11_0", 0, row, labels[0], clrGray, clrWhite);
   string txtBear = (resRJ[0].bearDist == DBL_MAX) ? "-" : (resRJ[0].bearHunted ? "Hunted" : DoubleToString(resRJ[0].bearPrice, _Digits));
   string txtBull = (resRJ[0].bullDist == DBL_MAX) ? "-" : (resRJ[0].bullHunted ? "Hunted" : DoubleToString(resRJ[0].bullPrice, _Digits));
   DrawCell("R11_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R11_2", 2, row, txtBull, clrBlack, clrWhite);

   // 2. Weekly Swing
   row--; // 10
   DrawCell("R10_0", 0, row, labels[1], clrGray, clrWhite);
   txtBear = (resSw[0].bearDist == DBL_MAX) ? "-" : (resSw[0].bearHunted ? "Hunted" : DoubleToString(resSw[0].bearPrice, _Digits));
   txtBull = (resSw[0].bullDist == DBL_MAX) ? "-" : (resSw[0].bullHunted ? "Hunted" : DoubleToString(resSw[0].bullPrice, _Digits));
   DrawCell("R10_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R10_2", 2, row, txtBull, clrBlack, clrWhite);

   // 3. Weekly PWH/L
   row--; // 9
   DrawCell("R9_0", 0, row, labels[2], clrGray, clrWhite);
   txtBear = (pwh==0) ? "-" : (pwhHunted ? "Hunted" : DoubleToString(pwh, _Digits));
   txtBull = (pwl==0) ? "-" : (pwlHunted ? "Hunted" : DoubleToString(pwl, _Digits));
   DrawCell("R9_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R9_2", 2, row, txtBull, clrBlack, clrWhite);

   // 4. Daily RJ
   row--; // 8
   DrawCell("R8_0", 0, row, labels[3], clrGray, clrWhite);
   txtBear = (resRJ[1].bearDist == DBL_MAX) ? "-" : (resRJ[1].bearHunted ? "Hunted" : DoubleToString(resRJ[1].bearPrice, _Digits));
   txtBull = (resRJ[1].bullDist == DBL_MAX) ? "-" : (resRJ[1].bullHunted ? "Hunted" : DoubleToString(resRJ[1].bullPrice, _Digits));
   DrawCell("R8_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R8_2", 2, row, txtBull, clrBlack, clrWhite);

   // 5. Daily Swing
   row--; // 7
   DrawCell("R7_0", 0, row, labels[4], clrGray, clrWhite);
   txtBear = (resSw[1].bearDist == DBL_MAX) ? "-" : (resSw[1].bearHunted ? "Hunted" : DoubleToString(resSw[1].bearPrice, _Digits));
   txtBull = (resSw[1].bullDist == DBL_MAX) ? "-" : (resSw[1].bullHunted ? "Hunted" : DoubleToString(resSw[1].bullPrice, _Digits));
   DrawCell("R7_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R7_2", 2, row, txtBull, clrBlack, clrWhite);

   // 6. Daily yH/L
   row--; // 6
   DrawCell("R6_0", 0, row, labels[5], clrGray, clrWhite);
   txtBear = (pdh==0) ? "-" : (pdhHunted ? "Hunted" : DoubleToString(pdh, _Digits));
   txtBull = (pdl==0) ? "-" : (pdlHunted ? "Hunted" : DoubleToString(pdl, _Digits));
   DrawCell("R6_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R6_2", 2, row, txtBull, clrBlack, clrWhite);

   // 7. 4H RJ
   row--; // 5
   DrawCell("R5_0", 0, row, labels[6], clrGray, clrWhite);
   txtBear = (resRJ[2].bearDist == DBL_MAX) ? "-" : (resRJ[2].bearHunted ? "Hunted" : DoubleToString(resRJ[2].bearPrice, _Digits));
   txtBull = (resRJ[2].bullDist == DBL_MAX) ? "-" : (resRJ[2].bullHunted ? "Hunted" : DoubleToString(resRJ[2].bullPrice, _Digits));
   DrawCell("R5_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R5_2", 2, row, txtBull, clrBlack, clrWhite);

   // 8. 4H Swing
   row--; // 4
   DrawCell("R4_0", 0, row, labels[7], clrGray, clrWhite);
   txtBear = (resSw[2].bearDist == DBL_MAX) ? "-" : (resSw[2].bearHunted ? "Hunted" : DoubleToString(resSw[2].bearPrice, _Digits));
   txtBull = (resSw[2].bullDist == DBL_MAX) ? "-" : (resSw[2].bullHunted ? "Hunted" : DoubleToString(resSw[2].bullPrice, _Digits));
   DrawCell("R4_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R4_2", 2, row, txtBull, clrBlack, clrWhite);

   // 9. 1H Swing
   row--; // 3
   DrawCell("R3_0", 0, row, labels[8], clrGray, clrWhite);
   txtBear = (resSw[3].bearDist == DBL_MAX) ? "-" : (resSw[3].bearHunted ? "Hunted" : DoubleToString(resSw[3].bearPrice, _Digits));
   txtBull = (resSw[3].bullDist == DBL_MAX) ? "-" : (resSw[3].bullHunted ? "Hunted" : DoubleToString(resSw[3].bullPrice, _Digits));
   DrawCell("R3_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R3_2", 2, row, txtBull, clrBlack, clrWhite);

   // 10. 30m Swing
   row--; // 2
   DrawCell("R2_0", 0, row, labels[9], clrGray, clrWhite);
   txtBear = (resSw[4].bearDist == DBL_MAX) ? "-" : (resSw[4].bearHunted ? "Hunted" : DoubleToString(resSw[4].bearPrice, _Digits));
   txtBull = (resSw[4].bullDist == DBL_MAX) ? "-" : (resSw[4].bullHunted ? "Hunted" : DoubleToString(resSw[4].bullPrice, _Digits));
   DrawCell("R2_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R2_2", 2, row, txtBull, clrBlack, clrWhite);

   // 11. 15m Swing
   row--; // 1
   DrawCell("R1_0", 0, row, labels[10], clrGray, clrWhite);
   txtBear = (resSw[5].bearDist == DBL_MAX) ? "-" : (resSw[5].bearHunted ? "Hunted" : DoubleToString(resSw[5].bearPrice, _Digits));
   txtBull = (resSw[5].bullDist == DBL_MAX) ? "-" : (resSw[5].bullHunted ? "Hunted" : DoubleToString(resSw[5].bullPrice, _Digits));
   DrawCell("R1_1", 1, row, txtBear, clrBlack, clrWhite);
   DrawCell("R1_2", 2, row, txtBull, clrBlack, clrWhite);

   // 12. 4H Raid
   row--; // 0 (Bottom)
   DrawCell("R0_0", 0, row, labels[11], clrGray, clrWhite);
   DrawCell("R0_1", 1, row, raid4HBear ? "RAID!" : "-", raid4HBear ? clrRed : clrBlack, clrWhite);
   DrawCell("R0_2", 2, row, raid4HBull ? "RAID!" : "-", raid4HBull ? clrGreen : clrBlack, clrWhite);
  }

//+------------------------------------------------------------------+
//| Custom Indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time_array[],
                const double &open_array[],
                const double &high_array[],
                const double &low_array[],
                const double &close_array[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < 2) return 0;

   int start = prev_calculated - 1;

   // --- Initialization ---
   if(prev_calculated == 0)
     {
      start = 0;
      datetime startTime = TimeCurrent() - InpMaxDaysBack * 86400;
      int startIdx = iBarShift(Symbol(), _Period, startTime);
      if(startIdx >= 0 && startIdx < rates_total) start = startIdx;

      // Reset Globals
      ListActiveRJs.Clear();
      ListActiveMtfSwings.Clear();
      ListHistoryStructures.Clear();
      ListActiveMinorSwings.Clear();

      g_state = 0;
      g_rangeHighPrice = 0; g_rangeHighTime = 0;
      g_rangeLowPrice = 0; g_rangeLowTime = 0;
      g_lastKnownSwingHighPrice = 0; g_lastKnownSwingHighTime = 0;
      g_lastKnownSwingLowPrice = 0; g_lastKnownSwingLowTime = 0;
      g_lineHigh = ""; g_lineLow = ""; g_labelHigh = ""; g_labelLow = "";

      ZeroMemory(g_buf_Local);
      ZeroMemory(g_buf_15m);
      ZeroMemory(g_buf_30m);
      ZeroMemory(g_buf_1H);
      ZeroMemory(g_buf_4H);
      ZeroMemory(g_buf_D);
      ZeroMemory(g_buf_W);
      ZeroMemory(g_buf_M);

      ObjectsDeleteAll(0, "RJ-");
      ObjectsDeleteAll(0, "SwH-");
      ObjectsDeleteAll(0, "SwL-");
      ObjectsDeleteAll(0, "Main");
      ObjectsDeleteAll(0, "Minor");
      ObjectsDeleteAll(0, "BOS");
      ObjectsDeleteAll(0, "Hist");
      ObjectsDeleteAll(0, "Extra");
     }
   if(start < 0) start = 0;

   // --- Main Loop ---
   for(int i = start; i < rates_total; i++)
     {
      datetime t = time_array[i];
      double h = high_array[i];
      double l = low_array[i];
      double c = close_array[i];
      double o = open_array[i];

      bool isConfirmed = (i < rates_total - 1);
      bool isLive = (i == rates_total - 1);

      // 1. MTF Management
      ManageMTFObjects(Symbol(), PERIOD_M15, InpVis15m, t, g_buf_15m);
      ManageMTFObjects(Symbol(), PERIOD_M30, InpVis30m, t, g_buf_30m);
      ManageMTFObjects(Symbol(), PERIOD_H1,  InpVis1H,  t, g_buf_1H);
      ManageMTFObjects(Symbol(), PERIOD_H4,  InpVis4H,  t, g_buf_4H);
      ManageMTFObjects(Symbol(), PERIOD_D1,  InpVisD,   t, g_buf_D);
      ManageMTFObjects(Symbol(), PERIOD_W1,  InpVisW,   t, g_buf_W);
      ManageMTFObjects(Symbol(), PERIOD_MN1, InpVisM,   t, g_buf_M);

      // 2. Mitigation
      ProcessMitigation(h, l, t, isConfirmed);

      // 3. Main Structure
      if(isConfirmed)
        {
         bool isRealTime = (i == rates_total - 2) && (prev_calculated > 0);
         ProcessMainStructure(i, high_array, low_array, close_array, open_array, time_array, 1.0, isRealTime);
        }
      else
        {
         if(g_state == 1 || g_state == 2 || g_state == 3)
           {
            if(ObjectFind(0, g_lineHigh) >= 0) UpdateLineX2(g_lineHigh, t);
            if(ObjectFind(0, g_lineLow) >= 0) UpdateLineX2(g_lineLow, t);
            if(ObjectFind(0, g_labelHigh) >= 0) UpdateLabelX(g_labelHigh, t);
            if(ObjectFind(0, g_labelLow) >= 0) UpdateLabelX(g_labelLow, t);
           }
        }

      // 4. Signals
      double minBearDist_W = DBL_MAX, minBullDist_W = DBL_MAX;
      bool huntBear_W = false, huntBull_W = false;

      double minBearDist_D = DBL_MAX, minBullDist_D = DBL_MAX;
      bool huntBear_D = false, huntBull_D = false;

      double minBearDist_4H = DBL_MAX, minBullDist_4H = DBL_MAX;
      bool huntBear_4H = false, huntBull_4H = false;

      // RJ Loop
      for(int k=0; k<ListActiveRJs.Total(); k++)
        {
         CRJO *objRJ = (CRJO*)ListActiveRJs.At(k);
         if(CheckPointer(objRJ) == POINTER_INVALID) continue;

         double dist = MathAbs(c - objRJ->m_price);
         bool hunted = (objRJ->m_mitigated_count != -1);

         if(objRJ->m_tf_name == "W")
           {
            if(objRJ->m_is_bearish) { if(dist < minBearDist_W) { minBearDist_W = dist; huntBear_W = hunted; } }
            else { if(dist < minBullDist_W) { minBullDist_W = dist; huntBull_W = hunted; } }
           }
         else if(objRJ->m_tf_name == "D")
           {
            if(objRJ->m_is_bearish) { if(dist < minBearDist_D) { minBearDist_D = dist; huntBear_D = hunted; } }
            else { if(dist < minBullDist_D) { minBullDist_D = dist; huntBull_D = hunted; } }
           }
         else if(objRJ->m_tf_name == "4h")
           {
            if(objRJ->m_is_bearish) { if(dist < minBearDist_4H) { minBearDist_4H = dist; huntBear_4H = hunted; } }
            else { if(dist < minBullDist_4H) { minBullDist_4H = dist; huntBull_4H = hunted; } }
           }
        }

      BufferRJ_W_BearHunted[i] = huntBear_W;
      BufferRJ_W_BullHunted[i] = huntBull_W;
      BufferRJ_D_BearHunted[i] = huntBear_D;
      BufferRJ_D_BullHunted[i] = huntBull_D;
      BufferRJ_4H_BearHunted[i] = huntBear_4H;
      BufferRJ_4H_BullHunted[i] = huntBull_4H;

      // Swings Loop
      double s_minBearDist_W = DBL_MAX, s_minBullDist_W = DBL_MAX;
      bool s_huntBear_W = false, s_huntBull_W = false;
      double s_minBearDist_D = DBL_MAX, s_minBullDist_D = DBL_MAX;
      bool s_huntBear_D = false, s_huntBull_D = false;
      double s_minBearDist_4H = DBL_MAX, s_minBullDist_4H = DBL_MAX;
      double s_bearPrice_4H = 0, s_bullPrice_4H = 0;
      bool s_huntBear_4H = false, s_huntBull_4H = false;
      double s_minBearDist_1H = DBL_MAX, s_minBullDist_1H = DBL_MAX;
      bool s_huntBear_1H = false, s_huntBull_1H = false;
      double s_minBearDist_30m = DBL_MAX, s_minBullDist_30m = DBL_MAX;
      bool s_huntBear_30m = false, s_huntBull_30m = false;
      double s_minBearDist_15m = DBL_MAX, s_minBullDist_15m = DBL_MAX;
      bool s_huntBear_15m = false, s_huntBull_15m = false;

      for(int k=0; k<ListActiveMtfSwings.Total(); k++)
        {
         CMtfSwingObj *objSw = (CMtfSwingObj*)ListActiveMtfSwings.At(k);
         if(CheckPointer(objSw) == POINTER_INVALID) continue;

         double dist = MathAbs(c - objSw->m_price);
         bool hunted = (objSw->m_mitigated_count != -1);
         string tf = objSw->m_tf_name;

         if(tf == "W") {
            if(objSw->m_is_bearish) { if(dist < s_minBearDist_W) { s_minBearDist_W = dist; s_huntBear_W = hunted; } }
            else { if(dist < s_minBullDist_W) { s_minBullDist_W = dist; s_huntBull_W = hunted; } }
         } else if(tf == "D") {
            if(objSw->m_is_bearish) { if(dist < s_minBearDist_D) { s_minBearDist_D = dist; s_huntBear_D = hunted; } }
            else { if(dist < s_minBullDist_D) { s_minBullDist_D = dist; s_huntBull_D = hunted; } }
         } else if(tf == "4h") {
            if(objSw->m_is_bearish) {
               if(dist < s_minBearDist_4H) {
                  s_minBearDist_4H = dist;
                  s_bearPrice_4H = objSw->m_price;
                  s_huntBear_4H = hunted;
               }
            } else {
               if(dist < s_minBullDist_4H) {
                  s_minBullDist_4H = dist;
                  s_bullPrice_4H = objSw->m_price;
                  s_huntBull_4H = hunted;
               }
            }
         } else if(tf == "1h") {
            if(objSw->m_is_bearish) { if(dist < s_minBearDist_1H) { s_minBearDist_1H = dist; s_huntBear_1H = hunted; } }
            else { if(dist < s_minBullDist_1H) { s_minBullDist_1H = dist; s_huntBull_1H = hunted; } }
         } else if(tf == "30m") {
            if(objSw->m_is_bearish) { if(dist < s_minBearDist_30m) { s_minBearDist_30m = dist; s_huntBear_30m = hunted; } }
            else { if(dist < s_minBullDist_30m) { s_minBullDist_30m = dist; s_huntBull_30m = hunted; } }
         } else if(tf == "15m") {
            if(objSw->m_is_bearish) { if(dist < s_minBearDist_15m) { s_minBearDist_15m = dist; s_huntBear_15m = hunted; } }
            else { if(dist < s_minBullDist_15m) { s_minBullDist_15m = dist; s_huntBull_15m = hunted; } }
         }
        }

      BufferSw_W_BearHunted[i] = s_huntBear_W;
      BufferSw_W_BullHunted[i] = s_huntBull_W;
      BufferSw_D_BearHunted[i] = s_huntBear_D;
      BufferSw_D_BullHunted[i] = s_huntBull_D;
      BufferSw_4H_BearHunted[i] = s_huntBear_4H;
      BufferSw_4H_BullHunted[i] = s_huntBull_4H;
      BufferSw_1H_BearHunted[i] = s_huntBear_1H;
      BufferSw_1H_BullHunted[i] = s_huntBull_1H;
      BufferSw_30m_BearHunted[i] = s_huntBear_30m;
      BufferSw_30m_BullHunted[i] = s_huntBull_30m;
      BufferSw_15m_BearHunted[i] = s_huntBear_15m;
      BufferSw_15m_BullHunted[i] = s_huntBull_15m;

      // Raid Logic (4H)
      bool isBearRaid = false;
      bool isBullRaid = false;

      if(s_bearPrice_4H != 0)
        {
         if(h > s_bearPrice_4H && c < s_bearPrice_4H) isBearRaid = true;
        }
      if(s_bullPrice_4H != 0)
        {
         if(l < s_bullPrice_4H && c > s_bullPrice_4H) isBullRaid = true;
        }

      BufferRaid_4H_Bear[i] = isBearRaid ? 1.0 : 0.0;
      BufferRaid_4H_Bull[i] = isBullRaid ? 1.0 : 0.0;
     }
   DrawExtraLevels(time_array[rates_total-1]);
   DrawDashboard(close_array[rates_total-1]);

   return(rates_total);
  }
//+------------------------------------------------------------------+

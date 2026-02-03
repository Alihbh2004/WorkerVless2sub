//+------------------------------------------------------------------+
//|                                        ICT_OrderBlocks_MTF.mq5   |
//|                        Transformed from Pine Script              |
//+------------------------------------------------------------------+
#property copyright "Jules"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

// ==========================================
// --- SETTINGS & INPUTS ---
// ==========================================

input group "General Style Settings"
input color defBullColor = clrTeal;     // Default/Other TF Bull Color
input color defBearColor = clrMaroon;   // Default/Other TF Bear Color
input color lineColor    = clrBlack;    // Daily/Weekly Line Color
input int   lineWidth    = 1;           // Daily/Weekly Line Width
input bool  showLabels   = true;        // Show Labels
input int   maxActiveOBs = 20;          // Max Active Memory per TF (3-100)
input int   visibleOBCount = 3;         // Visible Count (Last N) (1-20)
input int   mitigationDelay = 3;        // Mitigation Delay (Candles) (0-50)
input color mitigatedColor = clrGray;   // Mitigated Color

input group "15-Minute OB Settings (Display as Box)"
input color bullBox15m = clrGreen;      // 15m Bull Box Color
input color bearBox15m = clrRed;        // 15m Bear Box Color

input group "1-Hour OB Settings (Display as Box)"
input bool  show1H     = true;          // Show 1H OBs
input color bullBox1H  = clrGreen;      // 1H Bull Box Color
input color bearBox1H  = clrRed;        // 1H Bear Box Color
input int   minChart1H = 1;             // Min Chart TF (min)
input int   maxChart1H = 30;            // Max Chart TF (min)

input group "4-Hour OB Settings (Display as Box)"
input bool  show4H     = true;          // Show 4H OBs
input color bullBox4H  = clrLime;       // 4H Bull Box Color
input color bearBox4H  = clrMaroon;     // 4H Bear Box Color
input int   minChart4H = 15;            // Min Chart TF (min)
input int   maxChart4H = 60;            // Max Chart TF (min)

input group "Daily OB Settings (Display as 3 Lines)"
input bool  showDaily  = true;          // Show Daily OBs
input int   minChartD  = 60;            // Min Chart TF (min)
input int   maxChartD  = 1440;          // Max Chart TF (min)

input group "Weekly OB Settings (Display as 3 Lines)"
input bool  showWeekly = true;          // Show Weekly OBs
input int   minChartW  = 240;           // Min Chart TF (min)
input int   maxChartW  = 10080;         // Max Chart TF (min)

// ==========================================
// --- DATA STRUCTURES & ARRAYS ---
// ==========================================

struct Local_OB {
   string   id;               // Object name for the Box
   double   top;
   double   bottom;
   bool     is_mitigated;
   int      mitigation_idx;   // Bar index when mitigation happened
   datetime creation_time;    // Time when created (for sorting/identification)
};

struct MTF_OB {
   // Line 1
   string   l_1;
   string   lb_1;
   double   p_1;
   bool     active_1;
   int      dead_idx_1;

   // Line 2
   string   l_2;
   string   lb_2;
   double   p_2;
   bool     active_2;
   int      dead_idx_2;

   // Line 3
   string   l_3;
   string   lb_3;
   double   p_3;
   bool     active_3;
   int      dead_idx_3;

   // Box Mode
   string   b_main;
   double   box_top;
   double   box_bottom;

   // Common
   datetime startTime;
   string   tf_name;
   bool     isBoxMode;
   bool     isBullish;
   bool     is_mitigated;
   int      mitigation_idx;
};

// Global Arrays
Local_OB boxBull[];
Local_OB boxBear[];

MTF_OB lineBull1H[];
MTF_OB lineBear1H[];
MTF_OB lineBull4H[];
MTF_OB lineBear4H[];
MTF_OB lineBullD[];
MTF_OB lineBearD[];
MTF_OB lineBullW[];
MTF_OB lineBearW[];

// ==========================================
// --- HELPER FUNCTIONS ---
// ==========================================

int GetChartMinutes()
  {
   return PeriodSeconds() / 60;
  }

string CreateBox(datetime t1, double price1, datetime t2, double price2, color clr, string textStr, color txtColor, string namePrefix)
  {
   static int counter = 0;
   counter++;
   string name = "ICT_OB_" + namePrefix + "_" + IntegerToString(GetTickCount()) + "_" + IntegerToString(counter);
   if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, price1, t2, price2))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);      // Border color
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);      // Background (filled) behind candles
      ObjectSetInteger(0, name, OBJPROP_FILL, true);      // Enable fill

      // Text properties (Note: Standard Rect doesn't fully support separate text color from border easily in all modes,
      // but we set properties as requested)
      ObjectSetString(0, name, OBJPROP_TEXT, textStr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      return name;
     }
   return "";
  }

string CreateLine(datetime t1, double p1, datetime t2, double p2, color clr, int width, string namePrefix)
  {
   static int counter = 0;
   counter++;
   string name = "ICT_OB_Ln_" + namePrefix + "_" + IntegerToString(GetTickCount()) + "_" + IntegerToString(counter);
   if(ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      return name;
     }
   return "";
  }

string CreateLabel(datetime t, double p, string text, color clr, string namePrefix)
  {
   static int counter = 0;
   counter++;
   string name = "ICT_OB_Lb_" + namePrefix + "_" + IntegerToString(GetTickCount()) + "_" + IntegerToString(counter);
   if(ObjectCreate(0, name, OBJ_TEXT, 0, t, p))
     {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);
      return name;
     }
   return "";
  }

void DeleteLocalOB(Local_OB &ob)
  {
   if(ob.id != "") ObjectDelete(0, ob.id);
  }

void DeleteMTFOB(MTF_OB &ob)
  {
   if(ob.isBoxMode)
     {
      if(ob.b_main != "") ObjectDelete(0, ob.b_main);
     }
   else
     {
      if(ob.l_1 != "") ObjectDelete(0, ob.l_1);
      if(ob.lb_1 != "") ObjectDelete(0, ob.lb_1);
      if(ob.l_2 != "") ObjectDelete(0, ob.l_2);
      if(ob.lb_2 != "") ObjectDelete(0, ob.lb_2);
      if(ob.l_3 != "") ObjectDelete(0, ob.l_3);
      if(ob.lb_3 != "") ObjectDelete(0, ob.lb_3);
     }
  }

// Returns true if any OB found. Fills b_ (bull) and r_ (bear/red) arrays.
// Arrays: [0]=Open, [1]=Top, [2]=Bot, [3]=Close
void CalcOBLogic(string sym, ENUM_TIMEFRAMES tf, int shift,
                 double &b_data[], datetime &b_time,
                 double &r_data[], datetime &r_time)
  {
   // Initialize results to 0/Empty
   ArrayInitialize(b_data, 0.0);
   b_time = 0;
   ArrayInitialize(r_data, 0.0);
   r_time = 0;

   // We need data for shift+1, shift+2, shift+3
   // Check if enough bars
   if(iBars(sym, tf) <= shift + 4) return;

   // Retrieve Data
   // shift is "current" (Pine [0]), so [1] is shift+1
   double c1 = iClose(sym, tf, shift + 1);
   double o1 = iOpen(sym, tf, shift + 1);
   double h1 = iHigh(sym, tf, shift + 1);
   double l1 = iLow(sym, tf, shift + 1);

   double c2 = iClose(sym, tf, shift + 2);
   double o2 = iOpen(sym, tf, shift + 2);
   double h2 = iHigh(sym, tf, shift + 2);
   double l2 = iLow(sym, tf, shift + 2);
   datetime t2 = iTime(sym, tf, shift + 2);

   double c3 = iClose(sym, tf, shift + 3);
   double o3 = iOpen(sym, tf, shift + 3);
   double h3 = iHigh(sym, tf, shift + 3);
   double l3 = iLow(sym, tf, shift + 3);
   datetime t3 = iTime(sym, tf, shift + 3);

   // --- Bullish Logic ---
   // bool bullA = close[2] < open[2] and close[1] > high[2]
   bool bullA = (c2 < o2) && (c1 > h2);

   // bool bullB = close[3] < open[3] and close[1] > high[3] and close[2] <= high[3] and close[1] > high[2]
   bool bullB = (c3 < o3) && (c1 > h3) && (c2 <= h3) && (c1 > h2);

   if (bullA) {
       // Open
       b_data[0] = o2;
       // Top = high[2]
       b_data[1] = h2;
       // Bot = min(low[2], low[1])
       b_data[2] = MathMin(l2, iLow(sym, tf, shift + 1));
       // Close
       b_data[3] = c2;
       // Time
       b_time = t2;
   } else if (bullB) {
       b_data[0] = o3;
       // Top = high[3]
       b_data[1] = h3;
       // Bot = min(low[3], low[2], low[1])
       b_data[2] = MathMin(l3, MathMin(l2, iLow(sym, tf, shift + 1)));
       b_data[3] = c3;
       b_time = t3;
   }

   // --- Bearish Logic ---
   // bool bearA = close[2] > open[2] and close[1] < low[2]
   bool bearA = (c2 > o2) && (c1 < l2);

   // bool bearB = close[3] > open[3] and close[1] < low[3] and close[2] >= low[3] and close[1] < low[2]
   bool bearB = (c3 > o3) && (c1 < l3) && (c2 >= l3) && (c1 < l2);

   if (bearA) {
       r_data[0] = o2;
       // Top = max(high[2], high[1])
       r_data[1] = MathMax(h2, iHigh(sym, tf, shift + 1));
       // Bot = low[2]
       r_data[2] = l2;
       r_data[3] = c2;
       r_time = t2;
   } else if (bearB) {
       r_data[0] = o3;
       // Top = max(high[3], high[2], high[1])
       r_data[1] = MathMax(h3, MathMax(h2, iHigh(sym, tf, shift + 1)));
       r_data[2] = l3;
       r_data[3] = c3;
       r_time = t3;
   }
  }

// --- Management Functions ---

void ManageBoxes(Local_OB &boxesArray[], bool isBullish, double currentLow, double currentHigh, int currentBarIndex, datetime currentTime)
  {
   int total = ArraySize(boxesArray);
   if(total == 0) return;

   for(int i = total - 1; i >= 0; i--)
     {
      Local_OB ob = boxesArray[i]; // Copy

      bool isTouched = false;
      if(isBullish)
        {
         if(currentLow <= ob.top) isTouched = true;
        }
      else
        {
         if(currentHigh >= ob.bottom) isTouched = true;
        }

      if(isTouched && !ob.is_mitigated)
        {
         ob.is_mitigated = true;
         ob.mitigation_idx = currentBarIndex;
         // Update visual immediately
         if(ObjectFind(0, ob.id) >= 0)
           {
            ObjectSetInteger(0, ob.id, OBJPROP_COLOR, mitigatedColor);
           }
         boxesArray[i] = ob; // Update struct in array
        }

      bool shouldDelete = false;
      if(ob.is_mitigated)
        {
         if((currentBarIndex - ob.mitigation_idx) >= mitigationDelay) shouldDelete = true;
        }

      if(shouldDelete)
        {
         DeleteLocalOB(ob);
         ArrayRemove(boxesArray, i, 1);
        }
      else
        {
         // Extend to current time
         if(ObjectFind(0, ob.id) >= 0)
            ObjectSetInteger(0, ob.id, OBJPROP_TIME, 1, currentTime);
        }
     }
  }

void ManageMTF(MTF_OB &obArray[], bool isBullish, double currentLow, double currentHigh, int currentBarIndex, datetime currentTime, bool isDailyChart)
  {
   int total = ArraySize(obArray);
   if(total == 0) return;

   for(int i = total - 1; i >= 0; i--)
     {
      MTF_OB ob = obArray[i];

      bool shouldDelete = false;

      if(ob.isBoxMode)
        {
         bool isTouched = false;
         if(isBullish)
           {
            if(currentLow <= ob.box_top) isTouched = true;
           }
         else
           {
            if(currentHigh >= ob.box_bottom) isTouched = true;
           }

         if(isTouched && !ob.is_mitigated)
           {
            ob.is_mitigated = true;
            ob.mitigation_idx = currentBarIndex;
            // Update visual
            if(ObjectFind(0, ob.b_main) >= 0)
               ObjectSetInteger(0, ob.b_main, OBJPROP_COLOR, mitigatedColor);
            obArray[i] = ob;
           }

         if(ob.is_mitigated)
           {
            if((currentBarIndex - ob.mitigation_idx) >= mitigationDelay) shouldDelete = true;
           }

         if(shouldDelete)
           {
            DeleteMTFOB(ob);
            ArrayRemove(obArray, i, 1);
           }
         else
           {
             if(ObjectFind(0, ob.b_main) >= 0)
               ObjectSetInteger(0, ob.b_main, OBJPROP_TIME, 1, currentTime);
           }
        }
      else
        {
         // Lines Logic
         bool allLinesDeleted = true;

         // Line 1
         if(ob.active_1)
           {
            if(ob.dead_idx_1 == 0)
              {
               bool touch1 = isBullish ? (currentLow <= ob.p_1) : (currentHigh >= ob.p_1);
               if(touch1) ob.dead_idx_1 = currentBarIndex;
              }

            if(ob.dead_idx_1 > 0 && (currentBarIndex - ob.dead_idx_1 >= mitigationDelay))
              {
               if(ob.l_1 != "") ObjectDelete(0, ob.l_1);
               if(ob.lb_1 != "") ObjectDelete(0, ob.lb_1);
               ob.active_1 = false;
              }
            else
              {
               if(ObjectFind(0, ob.l_1) >= 0) ObjectSetInteger(0, ob.l_1, OBJPROP_TIME, 1, currentTime);
               if(ObjectFind(0, ob.lb_1) >= 0) ObjectSetInteger(0, ob.lb_1, OBJPROP_TIME, currentTime);
               allLinesDeleted = false;
              }
           }

         // Line 2
         if(ob.active_2)
           {
            if(ob.dead_idx_2 == 0)
              {
               bool touch2 = isBullish ? (currentLow <= ob.p_2) : (currentHigh >= ob.p_2);
               if(touch2) ob.dead_idx_2 = currentBarIndex;
              }

            if(ob.dead_idx_2 > 0 && (currentBarIndex - ob.dead_idx_2 >= mitigationDelay))
              {
               if(ob.l_2 != "") ObjectDelete(0, ob.l_2);
               if(ob.lb_2 != "") ObjectDelete(0, ob.lb_2);
               ob.active_2 = false;
              }
            else
              {
               if(ObjectFind(0, ob.l_2) >= 0) ObjectSetInteger(0, ob.l_2, OBJPROP_TIME, 1, currentTime);
               if(ObjectFind(0, ob.lb_2) >= 0) ObjectSetInteger(0, ob.lb_2, OBJPROP_TIME, currentTime);
               allLinesDeleted = false;
              }
           }

         // Line 3
         if(ob.active_3)
           {
            if(ob.dead_idx_3 == 0)
              {
               bool touch3 = isBullish ? (currentLow <= ob.p_3) : (currentHigh >= ob.p_3);
               if(touch3) ob.dead_idx_3 = currentBarIndex;
              }

            if(ob.dead_idx_3 > 0 && (currentBarIndex - ob.dead_idx_3 >= mitigationDelay))
              {
               if(ob.l_3 != "") ObjectDelete(0, ob.l_3);
               if(ob.lb_3 != "") ObjectDelete(0, ob.lb_3);
               ob.active_3 = false;
              }
            else
              {
               if(ObjectFind(0, ob.l_3) >= 0) ObjectSetInteger(0, ob.l_3, OBJPROP_TIME, 1, currentTime);
               if(ObjectFind(0, ob.lb_3) >= 0) ObjectSetInteger(0, ob.lb_3, OBJPROP_TIME, currentTime);
               allLinesDeleted = false;
              }
           }

         obArray[i] = ob; // Update struct

         if(allLinesDeleted)
           {
            DeleteMTFOB(ob); // Just in case leftovers
            ArrayRemove(obArray, i, 1);
           }
        }
     }
  }

void ManageVisibility(MTF_OB &obArray[], bool isEnabled, int minChartMin, int maxChartMin, color boxColorBull, color boxColorBear)
  {
   int size = ArraySize(obArray);
   if(size == 0) return;

   int currentChartMin = GetChartMinutes();
   bool isWithinRange = (currentChartMin >= minChartMin) && (currentChartMin <= maxChartMin);
   bool shouldShow = isEnabled && isWithinRange;

   int limit = visibleOBCount;
   int startIndex = size - limit;
   if(startIndex < 0) startIndex = 0;

   for(int i = 0; i < size; i++)
     {
      MTF_OB ob = obArray[i];
      bool isRecent = (i >= startIndex);
      bool finalVisible = shouldShow && isRecent;

      if(ob.isBoxMode)
        {
         color baseC = ob.isBullish ? boxColorBull : boxColorBear;
         color finalBg = ob.is_mitigated ? mitigatedColor : baseC;

         long periods = finalVisible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
         if(ObjectFind(0, ob.b_main) >= 0)
           {
            ObjectSetInteger(0, ob.b_main, OBJPROP_TIMEFRAMES, periods);
            // Also ensure color is correct if visible
            if(finalVisible)
               ObjectSetInteger(0, ob.b_main, OBJPROP_COLOR, finalBg);
           }
        }
      else
        {
         // Lines
         long periods = finalVisible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;

         // L1
         if(ob.active_1 && ObjectFind(0, ob.l_1) >= 0)
           {
            ObjectSetInteger(0, ob.l_1, OBJPROP_TIMEFRAMES, periods);
            ObjectSetInteger(0, ob.lb_1, OBJPROP_TIMEFRAMES, periods);
            if(finalVisible) {
               color c = (ob.dead_idx_1 > 0) ? mitigatedColor : lineColor;
               ObjectSetInteger(0, ob.l_1, OBJPROP_COLOR, c);
               ObjectSetInteger(0, ob.lb_1, OBJPROP_COLOR, c);
            }
           }
         // L2
         if(ob.active_2 && ObjectFind(0, ob.l_2) >= 0)
           {
            ObjectSetInteger(0, ob.l_2, OBJPROP_TIMEFRAMES, periods);
            ObjectSetInteger(0, ob.lb_2, OBJPROP_TIMEFRAMES, periods);
            if(finalVisible) {
               color c = (ob.dead_idx_2 > 0) ? mitigatedColor : lineColor;
               ObjectSetInteger(0, ob.l_2, OBJPROP_COLOR, c);
               ObjectSetInteger(0, ob.lb_2, OBJPROP_COLOR, c);
            }
           }
         // L3
         if(ob.active_3 && ObjectFind(0, ob.l_3) >= 0)
           {
            ObjectSetInteger(0, ob.l_3, OBJPROP_TIMEFRAMES, periods);
            ObjectSetInteger(0, ob.lb_3, OBJPROP_TIMEFRAMES, periods);
            if(finalVisible) {
               color c = (ob.dead_idx_3 > 0) ? mitigatedColor : lineColor;
               ObjectSetInteger(0, ob.l_3, OBJPROP_COLOR, c);
               ObjectSetInteger(0, ob.lb_3, OBJPROP_COLOR, c);
            }
           }
        }
     }
  }

void ManageLocalVisibility(Local_OB &boxesArray[], int limitCount, color normalColor)
  {
   int size = ArraySize(boxesArray);
   if(size == 0) return;

   int startIndex = size - limitCount;
   if(startIndex < 0) startIndex = 0;

   for(int i = 0; i < size; i++)
     {
      Local_OB ob = boxesArray[i];
      bool isVisible = (i >= startIndex);

      long periods = isVisible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;

      if(ObjectFind(0, ob.id) >= 0)
        {
         ObjectSetInteger(0, ob.id, OBJPROP_TIMEFRAMES, periods);
         if(isVisible)
           {
            color c = ob.is_mitigated ? mitigatedColor : normalColor;
            ObjectSetInteger(0, ob.id, OBJPROP_COLOR, c);
           }
        }
     }
  }

// Helper to check if MTF object exists to prevent duplication
bool IsDuplicateMTF(MTF_OB &arr[], datetime t)
  {
   int s = ArraySize(arr);
   if(s > 0 && arr[s-1].startTime == t) return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Validate Inputs
   if(maxActiveOBs < 3) maxActiveOBs = 3;
   if(maxActiveOBs > 100) maxActiveOBs = 100;

   if(visibleOBCount < 1) visibleOBCount = 1;
   if(visibleOBCount > 20) visibleOBCount = 20;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "ICT_OB_");
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   if(rates_total < 5) return(0);

   // --- Initialization ---
   if(prev_calculated == 0)
     {
      ObjectsDeleteAll(0, "ICT_OB_");
      ArrayResize(boxBull, 0);
      ArrayResize(boxBear, 0);
      ArrayResize(lineBull1H, 0); ArrayResize(lineBear1H, 0);
      ArrayResize(lineBull4H, 0); ArrayResize(lineBear4H, 0);
      ArrayResize(lineBullD, 0); ArrayResize(lineBearD, 0);
      ArrayResize(lineBullW, 0); ArrayResize(lineBearW, 0);
     }

   // --- Determine Local Box Colors based on Chart Timeframe ---
   color currentBullColor = defBullColor;
   color currentBearColor = defBearColor;
   int periodMin = GetChartMinutes();

   if(periodMin == 15) { currentBullColor = bullBox15m; currentBearColor = bearBox15m; }
   else if(periodMin == 60) { currentBullColor = bullBox1H; currentBearColor = bearBox1H; }
   else if(periodMin == 240) { currentBullColor = bullBox4H; currentBearColor = bearBox4H; }

   bool isChartD = (periodMin == 1440);
   bool isChartW = (periodMin == 10080);

   // --- Main Loop ---
   int start = prev_calculated - 1;
   if(start < 4) start = 4; // Need history for [3]

   for(int i = start; i < rates_total; i++)
     {
      // 1. Manage Existing Objects (Collision & Extension)
      ManageBoxes(boxBull, true, low[i], high[i], i, time[i]);
      ManageBoxes(boxBear, false, low[i], high[i], i, time[i]);

      ManageMTF(lineBull1H, true, low[i], high[i], i, time[i], false);
      ManageMTF(lineBear1H, false, low[i], high[i], i, time[i], false);

      ManageMTF(lineBull4H, true, low[i], high[i], i, time[i], false);
      ManageMTF(lineBear4H, false, low[i], high[i], i, time[i], false);

      ManageMTF(lineBullD, true, low[i], high[i], i, time[i], true);
      ManageMTF(lineBearD, false, low[i], high[i], i, time[i], true);

      ManageMTF(lineBullW, true, low[i], high[i], i, time[i], true);
      ManageMTF(lineBearW, false, low[i], high[i], i, time[i], true);


      // 2. MTF Logic Checks

      // H1
      if(show1H && periodMin < 60)
        {
         datetime tH1 = iTime(NULL, PERIOD_H1, iBarShift(NULL, PERIOD_H1, time[i]));
         datetime prevH1 = (i > 0) ? iTime(NULL, PERIOD_H1, iBarShift(NULL, PERIOD_H1, time[i-1])) : 0;
         if(tH1 != prevH1 && tH1 != 0)
           {
             int shift = iBarShift(NULL, PERIOD_H1, time[i]);
             double b_res[4], r_res[4]; datetime b_t, r_t;
             CalcOBLogic(NULL, PERIOD_H1, shift, b_res, b_t, r_res, r_t);

             if(b_t != 0 && !IsDuplicateMTF(lineBull1H, b_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = b_t; newObj.tf_name = "1h"; newObj.isBoxMode = true; newObj.isBullish = true;
                 newObj.box_top = b_res[1]; newObj.box_bottom = b_res[2];
                 newObj.b_main = CreateBox(b_t, b_res[1], time[i], b_res[2], bullBox1H, "ob-1h", clrWhite, "1H_Bull");
                 if(ArraySize(lineBull1H) >= maxActiveOBs) { DeleteMTFOB(lineBull1H[0]); ArrayRemove(lineBull1H, 0, 1); }
                 ArrayResize(lineBull1H, ArraySize(lineBull1H)+1); lineBull1H[ArraySize(lineBull1H)-1] = newObj;
             }
             if(r_t != 0 && !IsDuplicateMTF(lineBear1H, r_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = r_t; newObj.tf_name = "1h"; newObj.isBoxMode = true; newObj.isBullish = false;
                 newObj.box_top = r_res[1]; newObj.box_bottom = r_res[2];
                 newObj.b_main = CreateBox(r_t, r_res[1], time[i], r_res[2], bearBox1H, "ob-1h", clrWhite, "1H_Bear");
                 if(ArraySize(lineBear1H) >= maxActiveOBs) { DeleteMTFOB(lineBear1H[0]); ArrayRemove(lineBear1H, 0, 1); }
                 ArrayResize(lineBear1H, ArraySize(lineBear1H)+1); lineBear1H[ArraySize(lineBear1H)-1] = newObj;
             }
           }
        }

      // H4
      if(show4H && periodMin < 240)
        {
         datetime tH4 = iTime(NULL, PERIOD_H4, iBarShift(NULL, PERIOD_H4, time[i]));
         datetime prevH4 = (i > 0) ? iTime(NULL, PERIOD_H4, iBarShift(NULL, PERIOD_H4, time[i-1])) : 0;
         if(tH4 != prevH4 && tH4 != 0)
           {
             int shift = iBarShift(NULL, PERIOD_H4, time[i]);
             double b_res[4], r_res[4]; datetime b_t, r_t;
             CalcOBLogic(NULL, PERIOD_H4, shift, b_res, b_t, r_res, r_t);

             if(b_t != 0 && !IsDuplicateMTF(lineBull4H, b_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = b_t; newObj.tf_name = "4h"; newObj.isBoxMode = true; newObj.isBullish = true;
                 newObj.box_top = b_res[1]; newObj.box_bottom = b_res[2];
                 newObj.b_main = CreateBox(b_t, b_res[1], time[i], b_res[2], bullBox4H, "ob-4h", clrWhite, "4H_Bull");
                 if(ArraySize(lineBull4H) >= maxActiveOBs) { DeleteMTFOB(lineBull4H[0]); ArrayRemove(lineBull4H, 0, 1); }
                 ArrayResize(lineBull4H, ArraySize(lineBull4H)+1); lineBull4H[ArraySize(lineBull4H)-1] = newObj;
             }
             if(r_t != 0 && !IsDuplicateMTF(lineBear4H, r_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = r_t; newObj.tf_name = "4h"; newObj.isBoxMode = true; newObj.isBullish = false;
                 newObj.box_top = r_res[1]; newObj.box_bottom = r_res[2];
                 newObj.b_main = CreateBox(r_t, r_res[1], time[i], r_res[2], bearBox4H, "ob-4h", clrWhite, "4H_Bear");
                 if(ArraySize(lineBear4H) >= maxActiveOBs) { DeleteMTFOB(lineBear4H[0]); ArrayRemove(lineBear4H, 0, 1); }
                 ArrayResize(lineBear4H, ArraySize(lineBear4H)+1); lineBear4H[ArraySize(lineBear4H)-1] = newObj;
             }
           }
        }

      // Daily (Lines)
      if(showDaily)
        {
         datetime tD = iTime(NULL, PERIOD_D1, iBarShift(NULL, PERIOD_D1, time[i]));
         datetime prevD = (i > 0) ? iTime(NULL, PERIOD_D1, iBarShift(NULL, PERIOD_D1, time[i-1])) : 0;
         if(tD != prevD && tD != 0)
           {
             int shift = iBarShift(NULL, PERIOD_D1, time[i]);
             double b_res[4], r_res[4]; datetime b_t, r_t;
             CalcOBLogic(NULL, PERIOD_D1, shift, b_res, b_t, r_res, r_t);

             if(b_t != 0 && !IsDuplicateMTF(lineBullD, b_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = b_t; newObj.tf_name = "d"; newObj.isBoxMode = false; newObj.isBullish = true;

                 double p1 = b_res[0]; // Open
                 double p2 = (b_res[0] + b_res[3]) / 2.0; // Mid Body
                 double p3 = b_res[1]; // High (Bull)

                 newObj.l_1 = CreateLine(b_t, p1, time[i], p1, lineColor, lineWidth, "D_Bull_1");
                 newObj.lb_1 = showLabels ? CreateLabel(b_t, p1, "ob-d", lineColor, "D_Bull_1") : "";
                 newObj.p_1 = p1; newObj.active_1 = true;

                 newObj.l_2 = CreateLine(b_t, p2, time[i], p2, lineColor, lineWidth, "D_Bull_2");
                 newObj.lb_2 = showLabels ? CreateLabel(b_t, p2, "ob-d", lineColor, "D_Bull_2") : "";
                 newObj.p_2 = p2; newObj.active_2 = true;

                 newObj.l_3 = CreateLine(b_t, p3, time[i], p3, lineColor, lineWidth, "D_Bull_3");
                 newObj.lb_3 = showLabels ? CreateLabel(b_t, p3, "ob-d", lineColor, "D_Bull_3") : "";
                 newObj.p_3 = p3; newObj.active_3 = true;

                 if(ArraySize(lineBullD) >= maxActiveOBs) { DeleteMTFOB(lineBullD[0]); ArrayRemove(lineBullD, 0, 1); }
                 ArrayResize(lineBullD, ArraySize(lineBullD)+1); lineBullD[ArraySize(lineBullD)-1] = newObj;
             }

             if(r_t != 0 && !IsDuplicateMTF(lineBearD, r_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = r_t; newObj.tf_name = "d"; newObj.isBoxMode = false; newObj.isBullish = false;

                 double p1 = r_res[0]; double p2 = (r_res[0] + r_res[3]) / 2.0; double p3 = r_res[2];

                 newObj.l_1 = CreateLine(r_t, p1, time[i], p1, lineColor, lineWidth, "D_Bear_1");
                 newObj.lb_1 = showLabels ? CreateLabel(r_t, p1, "ob-d", lineColor, "D_Bear_1") : "";
                 newObj.p_1 = p1; newObj.active_1 = true;

                 newObj.l_2 = CreateLine(r_t, p2, time[i], p2, lineColor, lineWidth, "D_Bear_2");
                 newObj.lb_2 = showLabels ? CreateLabel(r_t, p2, "ob-d", lineColor, "D_Bear_2") : "";
                 newObj.p_2 = p2; newObj.active_2 = true;

                 newObj.l_3 = CreateLine(r_t, p3, time[i], p3, lineColor, lineWidth, "D_Bear_3");
                 newObj.lb_3 = showLabels ? CreateLabel(r_t, p3, "ob-d", lineColor, "D_Bear_3") : "";
                 newObj.p_3 = p3; newObj.active_3 = true;

                 if(ArraySize(lineBearD) >= maxActiveOBs) { DeleteMTFOB(lineBearD[0]); ArrayRemove(lineBearD, 0, 1); }
                 ArrayResize(lineBearD, ArraySize(lineBearD)+1); lineBearD[ArraySize(lineBearD)-1] = newObj;
             }
           }
        }

      // Weekly (Lines)
      if(showWeekly)
        {
         datetime tW = iTime(NULL, PERIOD_W1, iBarShift(NULL, PERIOD_W1, time[i]));
         datetime prevW = (i > 0) ? iTime(NULL, PERIOD_W1, iBarShift(NULL, PERIOD_W1, time[i-1])) : 0;
         if(tW != prevW && tW != 0)
           {
             int shift = iBarShift(NULL, PERIOD_W1, time[i]);
             double b_res[4], r_res[4]; datetime b_t, r_t;
             CalcOBLogic(NULL, PERIOD_W1, shift, b_res, b_t, r_res, r_t);

             if(b_t != 0 && !IsDuplicateMTF(lineBullW, b_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = b_t; newObj.tf_name = "w"; newObj.isBoxMode = false; newObj.isBullish = true;

                 double p1 = b_res[0]; double p2 = (b_res[0] + b_res[3]) / 2.0; double p3 = b_res[1];

                 newObj.l_1 = CreateLine(b_t, p1, time[i], p1, lineColor, lineWidth, "W_Bull_1");
                 newObj.lb_1 = showLabels ? CreateLabel(b_t, p1, "ob-w", lineColor, "W_Bull_1") : "";
                 newObj.p_1 = p1; newObj.active_1 = true;

                 newObj.l_2 = CreateLine(b_t, p2, time[i], p2, lineColor, lineWidth, "W_Bull_2");
                 newObj.lb_2 = showLabels ? CreateLabel(b_t, p2, "ob-w", lineColor, "W_Bull_2") : "";
                 newObj.p_2 = p2; newObj.active_2 = true;

                 newObj.l_3 = CreateLine(b_t, p3, time[i], p3, lineColor, lineWidth, "W_Bull_3");
                 newObj.lb_3 = showLabels ? CreateLabel(b_t, p3, "ob-w", lineColor, "W_Bull_3") : "";
                 newObj.p_3 = p3; newObj.active_3 = true;

                 if(ArraySize(lineBullW) >= maxActiveOBs) { DeleteMTFOB(lineBullW[0]); ArrayRemove(lineBullW, 0, 1); }
                 ArrayResize(lineBullW, ArraySize(lineBullW)+1); lineBullW[ArraySize(lineBullW)-1] = newObj;
             }

             if(r_t != 0 && !IsDuplicateMTF(lineBearW, r_t)) {
                 MTF_OB newObj = {};
                 newObj.startTime = r_t; newObj.tf_name = "w"; newObj.isBoxMode = false; newObj.isBullish = false;

                 double p1 = r_res[0]; double p2 = (r_res[0] + r_res[3]) / 2.0; double p3 = r_res[2];

                 newObj.l_1 = CreateLine(r_t, p1, time[i], p1, lineColor, lineWidth, "W_Bear_1");
                 newObj.lb_1 = showLabels ? CreateLabel(r_t, p1, "ob-w", lineColor, "W_Bear_1") : "";
                 newObj.p_1 = p1; newObj.active_1 = true;

                 newObj.l_2 = CreateLine(r_t, p2, time[i], p2, lineColor, lineWidth, "W_Bear_2");
                 newObj.lb_2 = showLabels ? CreateLabel(r_t, p2, "ob-w", lineColor, "W_Bear_2") : "";
                 newObj.p_2 = p2; newObj.active_2 = true;

                 newObj.l_3 = CreateLine(r_t, p3, time[i], p3, lineColor, lineWidth, "W_Bear_3");
                 newObj.lb_3 = showLabels ? CreateLabel(r_t, p3, "ob-w", lineColor, "W_Bear_3") : "";
                 newObj.p_3 = p3; newObj.active_3 = true;

                 if(ArraySize(lineBearW) >= maxActiveOBs) { DeleteMTFOB(lineBearW[0]); ArrayRemove(lineBearW, 0, 1); }
                 ArrayResize(lineBearW, ArraySize(lineBearW)+1); lineBearW[ArraySize(lineBearW)-1] = newObj;
             }
           }
        }

      // 3. Local OB Logic (Current Chart)
      if(!isChartD && !isChartW)
        {
         string tfTxt = "";
         if(periodMin < 60) tfTxt = IntegerToString(periodMin) + "m"; else tfTxt = IntegerToString(periodMin/60) + "h";

         // Bull Scen A: close[i-1] < open[i-1] && close[i] > high[i-1]
         bool bullScenA = (close[i-1] < open[i-1]) && (close[i] > high[i-1]);
         double bTopA = high[i-1];
         double bBotA = MathMin(low[i-1], low[i]);

         // Logic: Check if exists at time[i-1]. If condition true, ensure exists. If condition false, ensure deleted.
         // This handles real-time flicker.
         int idxA = -1;
         for(int k = ArraySize(boxBull)-1; k>=0; k--) { if(boxBull[k].creation_time == time[i-1]) { idxA = k; break; } if(ArraySize(boxBull)-k > 5) break; }

         if(bullScenA) {
             if(idxA == -1) {
                 // Create
                 Local_OB newLoc; newLoc.top = bTopA; newLoc.bottom = bBotA; newLoc.is_mitigated = false; newLoc.mitigation_idx = 0; newLoc.creation_time = time[i-1];
                 newLoc.id = CreateBox(time[i-1], bTopA, time[i], bBotA, currentBullColor, "ob-" + tfTxt, clrWhite, "Local_Bull");
                 if(ArraySize(boxBull) >= 50) { DeleteLocalOB(boxBull[0]); ArrayRemove(boxBull, 0, 1); }
                 ArrayResize(boxBull, ArraySize(boxBull)+1); boxBull[ArraySize(boxBull)-1] = newLoc;
             }
         } else {
             if(idxA != -1) {
                 DeleteLocalOB(boxBull[idxA]);
                 ArrayRemove(boxBull, idxA, 1);
             }
         }

         // Bull Scen B
         bool bullScenB = (close[i-2] < open[i-2]) && (close[i] > high[i-2]) && (close[i-1] <= high[i-2]) && (close[i] > high[i-1]);
         double bTopB = high[i-2];
         double bBotB = MathMin(low[i-2], MathMin(low[i-1], low[i]));

         int idxB = -1;
         for(int k = ArraySize(boxBull)-1; k>=0; k--) { if(boxBull[k].creation_time == time[i-2]) { idxB = k; break; } if(ArraySize(boxBull)-k > 5) break; }

         if(bullScenB) {
             if(idxB == -1) {
                 Local_OB newLoc; newLoc.top = bTopB; newLoc.bottom = bBotB; newLoc.is_mitigated = false; newLoc.mitigation_idx = 0; newLoc.creation_time = time[i-2];
                 newLoc.id = CreateBox(time[i-2], bTopB, time[i], bBotB, currentBullColor, "ob-" + tfTxt, clrWhite, "Local_Bull");
                 if(ArraySize(boxBull) >= 50) { DeleteLocalOB(boxBull[0]); ArrayRemove(boxBull, 0, 1); }
                 ArrayResize(boxBull, ArraySize(boxBull)+1); boxBull[ArraySize(boxBull)-1] = newLoc;
             }
         } else {
             if(idxB != -1) {
                 DeleteLocalOB(boxBull[idxB]);
                 ArrayRemove(boxBull, idxB, 1);
             }
         }

         // Bear Scen A
         bool bearScenA = (close[i-1] > open[i-1]) && (close[i] < low[i-1]);
         double rBotA = low[i-1];
         double rTopA = MathMax(high[i-1], high[i]);

         int idxRA = -1;
         for(int k = ArraySize(boxBear)-1; k>=0; k--) { if(boxBear[k].creation_time == time[i-1]) { idxRA = k; break; } if(ArraySize(boxBear)-k > 5) break; }

         if(bearScenA) {
             if(idxRA == -1) {
                 Local_OB newLoc; newLoc.top = rTopA; newLoc.bottom = rBotA; newLoc.is_mitigated = false; newLoc.mitigation_idx = 0; newLoc.creation_time = time[i-1];
                 newLoc.id = CreateBox(time[i-1], rTopA, time[i], rBotA, currentBearColor, "ob-" + tfTxt, clrWhite, "Local_Bear");
                 if(ArraySize(boxBear) >= 50) { DeleteLocalOB(boxBear[0]); ArrayRemove(boxBear, 0, 1); }
                 ArrayResize(boxBear, ArraySize(boxBear)+1); boxBear[ArraySize(boxBear)-1] = newLoc;
             }
         } else {
             if(idxRA != -1) {
                 DeleteLocalOB(boxBear[idxRA]);
                 ArrayRemove(boxBear, idxRA, 1);
             }
         }

         // Bear Scen B
         bool bearScenB = (close[i-2] > open[i-2]) && (close[i] < low[i-2]) && (close[i-1] >= low[i-2]) && (close[i] < low[i-1]);
         double rBotB = low[i-2];
         double rTopB = MathMax(high[i-2], MathMax(high[i-1], high[i]));

         int idxRB = -1;
         for(int k = ArraySize(boxBear)-1; k>=0; k--) { if(boxBear[k].creation_time == time[i-2]) { idxRB = k; break; } if(ArraySize(boxBear)-k > 5) break; }

         if(bearScenB) {
             if(idxRB == -1) {
                 Local_OB newLoc; newLoc.top = rTopB; newLoc.bottom = rBotB; newLoc.is_mitigated = false; newLoc.mitigation_idx = 0; newLoc.creation_time = time[i-2];
                 newLoc.id = CreateBox(time[i-2], rTopB, time[i], rBotB, currentBearColor, "ob-" + tfTxt, clrWhite, "Local_Bear");
                 if(ArraySize(boxBear) >= 50) { DeleteLocalOB(boxBear[0]); ArrayRemove(boxBear, 0, 1); }
                 ArrayResize(boxBear, ArraySize(boxBear)+1); boxBear[ArraySize(boxBear)-1] = newLoc;
             }
         } else {
             if(idxRB != -1) {
                 DeleteLocalOB(boxBear[idxRB]);
                 ArrayRemove(boxBear, idxRB, 1);
             }
         }
        }
     }

   // --- Visibility Control (After Loop) ---
   ManageVisibility(lineBull1H, show1H, minChart1H, maxChart1H, bullBox1H, bearBox1H);
   ManageVisibility(lineBear1H, show1H, minChart1H, maxChart1H, bullBox1H, bearBox1H);

   ManageVisibility(lineBull4H, show4H, minChart4H, maxChart4H, bullBox4H, bearBox4H);
   ManageVisibility(lineBear4H, show4H, minChart4H, maxChart4H, bullBox4H, bearBox4H);

   ManageVisibility(lineBullD, showDaily, minChartD, maxChartD, clrNone, clrNone);
   ManageVisibility(lineBearD, showDaily, minChartD, maxChartD, clrNone, clrNone);

   ManageVisibility(lineBullW, showWeekly, minChartW, maxChartW, clrNone, clrNone);
   ManageVisibility(lineBearW, showWeekly, minChartW, maxChartW, clrNone, clrNone);

   ManageLocalVisibility(boxBull, visibleOBCount, currentBullColor);
   ManageLocalVisibility(boxBear, visibleOBCount, currentBearColor);

   return(rates_total);
  }
//+------------------------------------------------------------------+

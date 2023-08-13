//+------------------------------------------------------------------+
//|                                    pyqtraderEWLabelsAndLines.mq4 |
//|                                   Copyright 2021-2023, pyqtrader |
//|                                           https://t.me/pyqtrader |
//+------------------------------------------------------------------+

/*
Press:
H for Help
,(comma) to remove the indicator
1 to label 12345 wave
A to label Abc wave
E to label abcdE wave
W to label Wxy wave
Y to label wxYxz wave
S to Select the wave of the selected label
=(equality sign) to select all labels
ESC to deselect all labels and lines
Q to increase the wave degree
SHIFT to decrease the wave degree
X to increase the label size or line width
Z to decrease the label size or line width
C to cycle through Colors
F to cycle through label Fonts or line styles
3 to reset the infobox wave to defaults
D to Draw line
V to to put arrow on the selected line
;(semi-colon) to select all lines
R to Remove the wave of the selected label if quick removal is allowed
tab/`(back quote)/space/win to effect drawing when Tab/BackQuote/Space/Winkey mode is on
Any key except the above to effect drawing when AnyKey mode is on
K to Kill and restart the indicator
*/

#property copyright "Copyright 2021-2023, pyqtrader, https://t.me/pyqtrader"
#property link      "https://t.me/pyqtrader"
#property version   "1.05"
#property strict
#property indicator_chart_window

#define  ARROW_DOWN  40
#define  ARROW_LEFT  37
#define  ARROW_RIGHT 39
#define  ARROW_UP    38
#define  BACKQUOTE   192
#define  CAPSLOCK    20
#define  COMMA       188
#define  CTRL        17
#define  DELETE      46
#define  EQUAL       187
#define  ESCAPE      27
#define  LETTER_A    65
#define  LETTER_B    66
#define  LETTER_C    67
#define  LETTER_D    68
#define  LETTER_E    69
#define  LETTER_F    70
#define  LETTER_H    72
#define  LETTER_K    75
#define  LETTER_Q    81
#define  LETTER_R    82
#define  LETTER_S    83
#define  LETTER_T    84
#define  LETTER_V    86
#define  LETTER_W    87
#define  LETTER_X    88
#define  LETTER_Y    89
#define  LETTER_Z    90
#define  NUMBER_0    48
#define  NUMBER_1    49
#define  NUMBER_3    51
#define  SEMICOLON   186
#define  SHIFT       16
#define  SPACE       32
#define  TAB         9
#define  WINKEY      91


enum yesno { Yes, No,};
enum elements { EmptyStart, Dline, Impulse, ABC_correction, ABCDE_correction, WXY_correction, WXYXZ_correction, EmptyEnd,};
enum controls {Tab, BackQuote, TabOrBackQuote, Winkey, Space, AnyKey, None,};
enum action_keyword {select_wave, unselect_wave, change_wave, increase_wave_degree, decrease_wave_degree, increase_fontsize, decrease_fontsize, change_colour, change_font, unselect_line,
                     increase_width, decrease_width, change_style, reset_to_defaults,
                    };

input color             LineColor = clrBlack;
input ENUM_LINE_STYLE   LineStyle = STYLE_SOLID;
input int               LineWidth = 2;
input bool              background = true;//Draw as background?
input controls          Control = None; //Additional key to toggle the drawing/labeling mode
double                  mouseclickpause = 0.2;//number of seconds before mouse is reactivated to prevent mouse slips
input yesno             ToggleModeOn = No; // Turn on the toggle mode?
input yesno             WaveRemovalOn = Yes; //Allow quick wave removal?
input yesno             ChangeIboxWhenSelectedLabelExists = Yes;//Change infobox when a label is selected?

input string            arrow_section = "//---------Arrow section---------------";
input int               arrow_size = 4;
input int               arrow_angle = 25;

struct waveID {bool itiswave; int degree; int count; string font; int fontsize; color colour;};
struct iboxparams {string name; string text; string font; string fontsize; color colour;};

string      versionN = "1.4";
int         click_counter = 5; // max number of clicks for an element is 5 for 1-2-3-4-5 wave, => 5 to prevent drawing before it is activated
datetime    timestamp = 0;

yesno       COMMERCIAL = No; //be sure to uncomment the OVERALL_LAST_DATE condition in the CommericalUse() function

elements       Element = EmptyStart;
const string   EWPREFIX = "elliottlabel";
const string   indicatorname = "EWLineDraw57763409", LINESPREFIX = "Drawing", INFOBOXPREFIX = "Infobox", STOREPREFIX = "ewlinestore", CCGVNAME = EWPREFIX + "ccounter";
const int      EWFULLPREFIXLEN = StringLen(EWPREFIX + (string)((int)TimeLocal())), impulse_init_degree = 5, correction_init_degree = 2, min_fontsize = 3, max_fontsize = 64, standard_fontsize = 8;
const int      elementsSIZE = (int) EmptyEnd + 1;
const int      STOREPREFIXFULLLEN = StringLen(STOREPREFIX) + 1; //+1 because (string) elements take 1 char
color          wavecolours[] = {clrBlack, clrDodgerBlue, clrRed, clrDarkGray, clrLimeGreen, clrMagenta,}, linecolours[] = {clrBlack, clrRed, clrSilver, clrDeepSkyBlue};
const string   wavefonts[] = {"Arial Bold", "Arial", "Arial Black", "Times New Roman",};
bool help_toggle = false;

const string impulse_waves[9][5] =
  {
     {"(I)", "(II)", "(III)", "(IV)", "(V)"},
     {"I)", "II)", "III)", "IV)", "V)"},
     {"I", "II", "III", "IV", "V"},
     {"(1)", "(2)", "(3)", "(4)", "(5)"},
     {"1)", "2)", "3)", "4)", "5)"},
     {"1", "2", "3", "4", "5"},
     {"(i)", "(ii)", "(iii)", "(iv)", "(v)"},
     {"i)", "ii)", "iii)", "iv)", "v)"},
     {"i", "ii", "iii", "iv", "v"},
  };

const string abcde_waves[6][5] =
  {
     {"(A)", "(B)", "(C)", "(D)", "(E)"},
     {"A)", "B)", "C)", "D)", "E)"},
     {"A", "B", "C", "D", "E"},
     {"(a)", "(b)", "(c)", "(d)", "(e)"},
     {"a)", "b)", "c)", "d)", "e)"},
     {"a", "b", "c", "d", "e"},
  };

const string wxyxz_waves[6][5] =
  {
     {"(W)", "(X)", "(Y)", "(X)", "(Z)"},
     {"W)", "X)", "Y)", "X)", "Z)"},
     {"W", "X", "Y", "X", "Z"},
     {"(w)", "(x)", "(y)", "(x)", "(z)"},
     {"w)", "x)", "y)", "x)", "z)"},
     {"w", "x", "y", "x", "z"},
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ElliottWave

  {
public:

                     ElliottWave(int x, elements el)
     {
      Reset(x, el);
     };

   void              Reset(int x, elements el)
     {
      elem = el;
      prefix = NULL;
      name = NULL;
      iboxname = INFOBOXPREFIX + (string)el;
      iboxtext = getIbxText();
      degree = x;
      clr = clrBlack;
      font = wavefonts[0];
      fontsize = 12;
     }

   void              PlaceLabel(int x, int y, elements type)
     {
      int w = 0;
      string label = NULL;
      datetime time;
      double price;

      ChartXYToTimePrice(0, x, y, w, time, price);

      switch(type)
        {
         case Impulse:
            if(click_counter < 5)
               label = impulse_waves[degree][click_counter];
            else
               label = NULL;
            break;

         case ABC_correction:
            if(click_counter < 3)
               label = abcde_waves[degree][click_counter];
            else
               label = NULL;
            break;

         case ABCDE_correction:
            if(click_counter < 5)
               label = abcde_waves[degree][click_counter];
            else
               label = NULL;
            break;

         case WXY_correction:
            if(click_counter < 3)
               label = wxyxz_waves[degree][click_counter];
            else
               label = NULL;
            break;

         case WXYXZ_correction:
            if(click_counter < 5)
               label = wxyxz_waves[degree][click_counter];
            else
               label = NULL;
            break;

         default:
            label = NULL;
            break;
        }

      if(click_counter == 0)
        {
         prefix = EWPREFIX + (string)((int)TimeLocal());
         timestamp = GetTickCount();
        }
      else
        {
         if(GetTickCount() - timestamp < mouseclickpause * 1000)
            return;
        }

      timestamp = GetTickCount();
      name = prefix + (string)Element + label + (string)MathRand();

      if(label != NULL)
        {
         ObjectCreate(0, name, OBJ_TEXT, w, time, price);
         ObjectSetString(0, name, OBJPROP_TEXT, label);
         ObjectSet(name, OBJPROP_COLOR, clr);
         ObjectSetString(0, name, OBJPROP_FONT, font);
         ObjectSet(name, OBJPROP_FONTSIZE, fontsize);
         ObjectSetInteger(0, name, OBJPROP_BACK, background);
        }

      click_counter++;

      if(type == ABC_correction || type == WXY_correction) //1.3 - to prevent switching wave type before placement of the current wave is finalized
        {if(click_counter > 2)click_counter = 5;}

     }

   void              Store()
     {
      store_ops("degree", (string)degree);
      store_ops("fontsize", (string) fontsize);
      store_ops("iboxname", iboxname);
      store_ops("iboxtext", iboxtext);
      store_ops("font", font);
      store_ops("clr", (string) clr);
      store_ops("prefix", prefix);
     }

   void              Restore() {restore_ops();}

   void              setDegree(int d) {degree = d;}
   void              setFont(string f) {font = f;}
   void              setFontsize(int fz) {fontsize = fz;}
   void              setClr(color c) {clr = c;}

   string            getIbxName() {return iboxname;}
   int               getDegree() {return degree;}
   string            getFont() {return font;}
   int               getFontsize() {return fontsize;}
   color             getClr() {return clr;}
   string            getIbxText() {update_iboxtext(); return iboxtext;}
   string            getPrefix() {return prefix;}


private:
   elements             elem;
   string               prefix, name, iboxname, iboxtext, font;
   int                  degree, fontsize;
   color                clr;
   datetime             timestamp;

   void              update_iboxtext()
     {
      switch(elem)
        {
         case EmptyStart:
            iboxtext = "n/a";
            break;
         case Dline:
            iboxtext = "n/a";
            break;
         case Impulse:
            iboxtext = impulse_waves[degree][0];
            break;
         case ABC_correction:
            iboxtext = abcde_waves[degree][0];
            break;
         case ABCDE_correction:
            iboxtext = abcde_waves[degree][4];
            break;
         case WXY_correction:
            iboxtext = wxyxz_waves[degree][0];
            break;
         case WXYXZ_correction:
            iboxtext = wxyxz_waves[degree][4];
            break;
         case EmptyEnd:
            iboxtext = "n/a";
            break;
         default:
            iboxtext = "n/a";
            break;
        }
     }

   void              store_ops(string var, string text)
     {
      string nm = STOREPREFIX + (string)elem + var;

      ObjectCreate(0, nm, OBJ_TEXT, 0, 0, 0);
      ObjectSet(nm, OBJPROP_COLOR, clrNONE);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, 0);
      ObjectSetString(0, nm, OBJPROP_TEXT, text);
     }

   void              restore_ops()
     {
      string nm, sfx, tx;

      for(int i = 0; i < ObjectsTotal(); i++)
        {
         nm = ObjectName(i);
         if(StringSubstr(nm, 0, STOREPREFIXFULLLEN) == STOREPREFIX + (string)elem)
           {

            sfx = StringSubstr(nm, STOREPREFIXFULLLEN);
            tx = ObjectGetString(0, nm, OBJPROP_TEXT, 0);

            if(sfx == "degree")
               degree = (int)tx;
            if(sfx == "fontsize")
               fontsize = (int) tx;
            if(sfx == "iboxname")
               iboxname = tx;
            if(sfx == "iboxtext")
               iboxtext = tx;
            if(sfx == "font")
               font = tx;
            if(sfx == "clr")
               clr = (color) tx;
            if(sfx == "prefix")
               prefix = tx;
           }
        }

      ObjectDelete(0, STOREPREFIX + (string)elem + "degree");
      ObjectDelete(0, STOREPREFIX + (string)elem + "style");
      ObjectDelete(0, STOREPREFIX + (string)elem + "fontsize");
      ObjectDelete(0, STOREPREFIX + (string)elem + "iboxname");
      ObjectDelete(0, STOREPREFIX + (string)elem + "iboxtext");
      ObjectDelete(0, STOREPREFIX + (string)elem + "font");
      ObjectDelete(0, STOREPREFIX + (string)elem + "clr");
     }

  };

class DrawLineManager

  {

public:

                     DrawLineManager(elements el) {Reset(el);};

   void                Reset(elements el)
     {
      elem = el;
      dlinename = NULL;
      width = LineWidth;
      style = LineStyle;
      clr = LineColor;
      iboxname = INFOBOXPREFIX + (string)Dline;
      iboxtext = getIbxText();
      iboxfont = "Arial";
      iboxfontsize = standard_fontsize;
     }

   void              Create(string name, datetime dt, double price)
     {
      ObjectCreate(0, name, OBJ_TREND, 0, dt, price, dt, price);
      ObjectSetInteger(0, name, OBJPROP_RAY, false);
      ObjectSet(name, OBJPROP_COLOR, clr);
      ObjectSet(name, OBJPROP_STYLE, style);
      ObjectSet(name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_BACK, background);
     }

   void              setWidth(int w) {width = w; update_iboxtext();}
   void              setStyle(int s) {style = s; update_iboxtext();}
   void              setClr(color c) {clr = c;}

   int               getWidth() {return width;}
   int               getStyle() {return style;}
   string            getIbxText() {update_iboxtext(); return iboxtext;}
   string            getIbxName() {return iboxname;}
   color             getClr() {return clr;}
   int               getIbxFontsize() {return iboxfontsize;}
   string            getIbxFont() {return iboxfont;}

   void              Store()
     {
      store_ops("width", (string)width);
      store_ops("style", (string) style);
      store_ops("iboxfontsize", (string) iboxfontsize);
      store_ops("iboxname", iboxname);
      store_ops("iboxtext", iboxtext);
      store_ops("iboxfont", iboxfont);
      store_ops("clr", (string) clr);
     }

   void              Restore() {restore_ops();}

   void              Printout()
     {
      Print("width=", (string)width);
      Print("style=", (string) style);
      Print("iboxfontsize=", (string) iboxfontsize);
      Print("iboxname=", iboxname);
      Print("iboxtext=", iboxtext);
      Print("iboxfont=", iboxfont);
      Print("clr=", (string) clr);
     }


private:

   elements          elem;
   string            dlinename;//reserved for names of specific objects(lines) if need be
   int               width, style, iboxfontsize;
   string            iboxname, iboxtext, iboxfont;
   color             clr;

   void              update_iboxtext()
     {
      string stylename;

      switch(style)
        {
         case 0:
            stylename = "Line";
            break;
         case 1:
            stylename = "Dash";
            break;
         case 2:
            stylename = "Dot";
            break;
         case 3:
            stylename = "DD";
            break;
         case 4:
            stylename = "DDD";
            break;
         default:
            stylename = "Line";
            break;
        }
      iboxtext = stylename + (string)width;
     }

   void              store_ops(string var, string text)
     {
      string nm = STOREPREFIX + (string)elem + var;

      ObjectCreate(0, nm, OBJ_TEXT, 0, 0, 0);
      ObjectSet(nm, OBJPROP_COLOR, clrNONE);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, 0);
      ObjectSetString(0, nm, OBJPROP_TEXT, text);
     }

   void              restore_ops()
     {
      string nm, sfx, tx;

      for(int i = 0; i < ObjectsTotal(); i++)
        {
         nm = ObjectName(i);
         if(StringSubstr(nm, 0, STOREPREFIXFULLLEN) == STOREPREFIX + (string)elem)
           {

            sfx = StringSubstr(nm, STOREPREFIXFULLLEN);
            tx = ObjectGetString(0, nm, OBJPROP_TEXT, 0);

            if(sfx == "width")
              {
               width = (int)tx;
               //Print(width);
              }
            if(sfx == "style")
               style = (int) tx;
            if(sfx == "iboxfontsize")
               iboxfontsize = (int) tx;
            if(sfx == "iboxname")
               iboxname = tx;
            if(sfx == "iboxtext")
               iboxtext = tx;
            if(sfx == "iboxfont")
               iboxfont = tx;
            if(sfx == "clr")
               clr = (color) tx;
           }
        }

      ObjectDelete(0, STOREPREFIX + (string)elem + "width");
      ObjectDelete(0, STOREPREFIX + (string)elem + "style");
      ObjectDelete(0, STOREPREFIX + (string)elem + "iboxfontsize");
      ObjectDelete(0, STOREPREFIX + (string)elem + "iboxname");
      ObjectDelete(0, STOREPREFIX + (string)elem + "iboxtext");
      ObjectDelete(0, STOREPREFIX + (string)elem + "iboxfont");
      ObjectDelete(0, STOREPREFIX + (string)elem + "clr");
     }

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class InfoboxManager
  {
public:

                     InfoboxManager() {Reset();};

   void              Create()
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      Refresh();
     }

   void              Delete()
     {

      ObjectDelete(0, name);

      for(int i = ObjectsTotal() - 1; i >= 0; i--)
        {
         if(StringFind(ObjectName(i), INFOBOXPREFIX, 0) == 0)
           {
            ObjectDelete(ObjectName(i));
           }
        }
     }

   void              Reset()
     {name = INFOBOXPREFIX; text = "Press H for help"; font = "Arial"; fontsize = standard_fontsize; clr = clrDarkGray;}

   void              Refresh()
     {
      ObjectSetInteger(0, name, OBJPROP_CORNER, 0);//2
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 5); //0,218
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 15);//12
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }

   bool              Exists()
     {
      string nm;
      for(int i = 0; i < ObjectsTotal(); i++)
        {
         nm = ObjectName(i);
         if(StringSubstr(nm, 0, StringLen(INFOBOXPREFIX)) == INFOBOXPREFIX)
            return true;
        }
      return false;
     }

   elements          CurrentElement()
     {
      Sync();
      return (elements) StringSubstr(name, StringLen(INFOBOXPREFIX));
     }

   void              Sync()
     {
      string nm;

      for(int i = 0; i < ObjectsTotal(); i++)
        {
         nm = ObjectName(i);

         if(StringFind(nm, INFOBOXPREFIX, 0) == 0)
           {
            name = nm;
            break;
           }
        }
      text = ObjectGetString(0, name, OBJPROP_TEXT, 0);
      font = ObjectGetString(0, name, OBJPROP_FONT, 0);
      fontsize = (int) ObjectGetInteger(0, name, OBJPROP_FONTSIZE, 0);
      clr = (color) ObjectGetInteger(0, name, OBJPROP_COLOR, 0);
     }

   void              setName(string n) {ObjectSetString(0, name, OBJPROP_NAME, n); name = n;}
   void              setText(string t) {text = t;}
   void              setFont(string f) {font = f;}
   void              setFontsize(int fz) {fontsize = fz;}
   void              setClr(color c) {clr = c;}

   string            getName() {return name;}
   string            getText() {return text;}
   string            getFont() {return font;}
   int               getFontsize() {return fontsize;}
   color             getClr() {return clr;}

private:

   string            name, text, font;
   int               fontsize;
   color             clr;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ElliottWave       ImpulseWave(impulse_init_degree, Impulse);
ElliottWave       ABCWave(correction_init_degree, ABC_correction);
ElliottWave       ABCDEWave(correction_init_degree, ABCDE_correction);
ElliottWave       WXYWave(correction_init_degree, WXY_correction);
ElliottWave       WXYXZWave(correction_init_degree, WXYXZ_correction);
DrawLineManager   DrawLine(Dline);
InfoboxManager    Infobox();

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int               OnInit()
  {

   IndicatorShortName(indicatorname);

//--- indicator buffers mapping
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

   if(Infobox.Exists() == true)
     {
      Element = Infobox.CurrentElement();

      DrawLine.Restore();
      ImpulseWave.Restore();
      ABCWave.Restore();
      ABCDEWave.Restore();
      WXYWave.Restore();
      WXYXZWave.Restore();

      click_counter = (int)ObjectGetString(0, CCGVNAME, OBJPROP_TEXT, 0);
      ObjectDelete(CCGVNAME);

     }
   else
      Infobox.Create();

// DrawLine.Printout();
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int               deinit()
  {
//Comment("");

   if(UninitializeReason() != REASON_REMOVE)
     {
      DrawLine.Store();
      ImpulseWave.Store();
      ABCWave.Store();
      ABCDEWave.Store();
      WXYWave.Store();
      WXYXZWave.Store();

      ObjectCreate(0, CCGVNAME, OBJ_TEXT, 0, 0, 0);
      ObjectSetString(0, CCGVNAME, OBJPROP_TEXT, (string) click_counter);
     }
   else
      Infobox.Delete();

   if(help_toggle == true)
     {
      help_toggle = false;
      Comment("");
     }

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int               OnCalculate(const int rates_total,
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

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void              OnChartEvent(const int id,
                               const long &lparam,
                               const double &dparam,
                               const string &sparam)
  {
   int      x = 0, y = 0, i = 0, key = 0;
   datetime dt = 0;
   double   price = 0;
   string   name;
   int      window = 0;

//---

   if(id == CHARTEVENT_KEYDOWN)
     {
      key = (int)lparam;

      switch(key)
        {
         case COMMA:
            ChartIndicatorDelete(0, 0, indicatorname);
            break;

         case SEMICOLON:
            for(i = 0; i < ObjectsTotal(); i++)
              {
               name = ObjectName(i);

               if(StringFind(name, LINESPREFIX, 0) != -1)
                  ObjectSetInteger(0, name, OBJPROP_SELECTED, true);
              }
            break;

         case DELETE:
            break;

         case BACKQUOTE:
            click_switcher(BackQuote);
            click_switcher(TabOrBackQuote);
            break;

         case TAB:
            click_switcher(Tab);
            click_switcher(TabOrBackQuote);
            break;

         case SPACE:
            click_switcher(Space);
            break;

         case WINKEY:
            click_switcher(Winkey);
            break;

         case LETTER_D:
            click_switcher(None);
            if(click_counter == 0 || click_counter >= 5)
              {
               Element = Dline;
               Infobox.setName(DrawLine.getIbxName());
               Infobox.setText(DrawLine.getIbxText());
               Infobox.setClr(DrawLine.getClr());
               Infobox.setFont(DrawLine.getIbxFont());
               Infobox.setFontsize(DrawLine.getIbxFontsize());
               Infobox.Refresh();
              }
            break;

         case LETTER_V:
            make_arrow();
            break;

         case NUMBER_1:
            click_switcher(None);
            if(click_counter == 0 || click_counter >= 5)
              {
               Element = Impulse;
               Infobox.setName(ImpulseWave.getIbxName());
               Infobox.setText(ImpulseWave.getIbxText());
               Infobox.setClr(ImpulseWave.getClr());
               Infobox.setFont(ImpulseWave.getFont());
               Infobox.setFontsize(ImpulseWave.getFontsize());
               Infobox.Refresh();
              }
            break;

         case LETTER_A:
            click_switcher(None);
            if(click_counter == 0 || click_counter >= 5)
              {
               Element = ABC_correction;
               Infobox.setName(ABCWave.getIbxName());
               Infobox.setText(ABCWave.getIbxText());
               Infobox.setClr(ABCWave.getClr());
               Infobox.setFont(ABCWave.getFont());
               Infobox.setFontsize(ABCWave.getFontsize());
               Infobox.Refresh();
              }
            break;

         case LETTER_E:
            click_switcher(None);
            if(click_counter == 0 || click_counter >= 5)
              {
               Element = ABCDE_correction;
               Infobox.setName(ABCDEWave.getIbxName());
               Infobox.setText(ABCDEWave.getIbxText());
               Infobox.setClr(ABCDEWave.getClr());
               Infobox.setFont(ABCDEWave.getFont());
               Infobox.setFontsize(ABCDEWave.getFontsize());
               Infobox.Refresh();
              }
            break;

         case LETTER_W:
            click_switcher(None);
            if(click_counter == 0 || click_counter >= 5)
              {
               Element = WXY_correction;
               Infobox.setName(WXYWave.getIbxName());
               Infobox.setText(WXYWave.getIbxText());
               Infobox.setClr(WXYWave.getClr());
               Infobox.setFont(WXYWave.getFont());
               Infobox.setFontsize(WXYWave.getFontsize());
               Infobox.Refresh();
              }
            break;

         case LETTER_Y:
            click_switcher(None);
            if(click_counter == 0 || click_counter >= 5)
              {
               Element = WXYXZ_correction;
               Infobox.setName(WXYXZWave.getIbxName());
               Infobox.setText(WXYXZWave.getIbxText());
               Infobox.setClr(WXYXZWave.getClr());
               Infobox.setFont(WXYXZWave.getFont());
               Infobox.setFontsize(WXYXZWave.getFontsize());
               Infobox.Refresh();
              }
            break;

         case LETTER_S:
            manage_wave(select_wave);
            break;

         case ESCAPE:
            AllWaves(unselect_wave);
            manage_line(unselect_line);
            break;

         case LETTER_Q:
            manage_wave(increase_wave_degree);
            Dispatcher(Element, increase_wave_degree);
            break;

         case SHIFT:
            manage_wave(decrease_wave_degree);
            Dispatcher(Element, decrease_wave_degree);
            break;

         case EQUAL:
            AllWaves(select_wave);
            break;

         case LETTER_X:
            manage_wave(increase_fontsize);
            manage_line(increase_width);
            Dispatcher(Element, increase_width);
            Dispatcher(Element, increase_fontsize);
            break;

         case LETTER_Z:
            manage_wave(decrease_fontsize);
            manage_line(decrease_width);
            Dispatcher(Element, decrease_width);
            Dispatcher(Element, decrease_fontsize);
            break;

         case LETTER_C:
            manage_wave(change_colour);
            manage_line(change_colour);
            Dispatcher(Element, change_colour);
            break;

         case LETTER_F:
            manage_wave(change_font);
            manage_line(change_style);
            Dispatcher(Element, change_style);
            Dispatcher(Element, change_font);
            break;

         case NUMBER_3:
            Dispatcher(Element, reset_to_defaults);
            break;

         case LETTER_H:
            help_toggle = (!help_toggle);
            show_help();
            break;

         case LETTER_R:
            if(WaveRemovalOn == Yes)
               delete_wave(Element);
            break;

         case LETTER_K:
            Infobox.Delete();
            hard_reset();
            Infobox.Create();
            break;

         default:
            click_switcher(AnyKey);
            break;
        }
     }

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      x = (int)lparam;
      y = (int)dparam;

      //-----------Dline-----------------------

      if(Element == Dline)
        {
         //Comment("POINT: ",x,",",y,",",sparam);
         ChartXYToTimePrice(0, x, y, window, dt, price);

         for(i = 0; i < ObjectsTotal(); i++)
           {
            name = ObjectName(i);

            if(name == "Active")
              {
               if(click_counter > 0 && GetTickCount() - timestamp > mouseclickpause * 1000 && sparam == "1") //5=4+1, 4 for SHIFT and 1 for left-click
                 {
                  ObjectSetString(0, name, OBJPROP_NAME, StringConcatenate(LINESPREFIX, (string)(int)TimeLocal()));
                  name = ObjectName(i);
                  if(ToggleModeOn == Yes && name != "Active")
                     click_counter = 0;
                  else
                     click_counter = 5;
                  return;
                 }
               else
                 {
                  ObjectMove(0, name, 1, dt, price);
                  return;
                 }
              }
           }

         if(sparam == "1" && click_counter == 0)//"1" for left-click
           {
            name = "Active";
            DrawLine.Create(name, dt, price);

            click_counter++;
            timestamp = GetTickCount();
           }

        }

      //-------------Elliott--------------
      if(sparam == "1")
        {
         switch(Element)
           {
            case Impulse:
               ImpulseWave.PlaceLabel(x, y, Impulse);
               break;

            case ABC_correction:
               ABCWave.PlaceLabel(x, y, ABC_correction);
               break;

            case ABCDE_correction:
               ABCDEWave.PlaceLabel(x, y, ABCDE_correction);
               break;

            case WXY_correction:
               WXYWave.PlaceLabel(x, y, WXY_correction);
               break;

            case WXYXZ_correction:
               WXYXZWave.PlaceLabel(x, y, WXYXZ_correction);
               break;

            default:
               break;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              Dispatcher(elements elem, action_keyword keyword)
  {
   int               temp = 0, sz = 0;
   ElliottWave*      EW;
   bool              ew_elem = false;

   if(ChangeIboxWhenSelectedLabelExists == No && selected_label_exists() == true)
      return;

   if(elem == Impulse || elem == ABC_correction || elem == ABCDE_correction || elem == WXY_correction || elem == WXYXZ_correction)
      ew_elem = true;
   else
      ew_elem = false;

   EW = ew_pointer(elem);

   switch(keyword)
     {
      case change_colour:
         if(elem == Dline)
           {
            temp = getColourIndex(Infobox.getClr(), linecolours);
            if(temp < ArraySize(linecolours) - 1)
               temp++;
            else
               temp = 0;
            DrawLine.setClr(linecolours[temp]);
            Infobox.setClr(linecolours[temp]);
            Infobox.Refresh();
           }
         else
           {
            if(ew_elem == false)
               break;
            temp = getColourIndex(Infobox.getClr(), wavecolours);
            if(temp < ArraySize(wavecolours) - 1)
               temp++;
            else
               temp = 0;
            EW.setClr(wavecolours[temp]);
            Infobox.setClr(wavecolours[temp]);
            Infobox.Refresh();
           }
         break;

      case reset_to_defaults:
         if(elem == EmptyStart || elem == EmptyEnd)
            break;
         if(elem == Dline)
           {
            DrawLine.Reset(elem);
            Infobox.setName(DrawLine.getIbxName());
            Infobox.setText(DrawLine.getIbxText());
            Infobox.setClr(DrawLine.getClr());
            Infobox.setFont(DrawLine.getIbxFont());
            Infobox.setFontsize(DrawLine.getIbxFontsize());
            Infobox.Refresh();
           }
         else
           {
            if(elem == Impulse)
               EW.Reset(impulse_init_degree, elem);
            else
               EW.Reset(correction_init_degree, elem);

            Infobox.setName(EW.getIbxName());
            Infobox.setText(EW.getIbxText());
            Infobox.setClr(EW.getClr());
            Infobox.setFont(EW.getFont());
            Infobox.setFontsize(EW.getFontsize());
            Infobox.Refresh();
           }
         break;

      case increase_width:

         if(elem != Dline)
            break;
         temp = DrawLine.getWidth();
         if(temp < 100)
            temp++;
         DrawLine.setWidth(temp);
         Infobox.setText(DrawLine.getIbxText());
         Infobox.Refresh();
         break;


      case decrease_width:

         if(elem != Dline)
            break;
         temp = DrawLine.getWidth();
         if(temp > 1)
            temp--;
         DrawLine.setWidth(temp);
         Infobox.setText(DrawLine.getIbxText());
         Infobox.Refresh();
         break;

      case change_style:

         if(elem != Dline)
            break;
         temp = DrawLine.getStyle();
         if(temp < 4)
            temp++;
         else
            temp = 0;
         DrawLine.setStyle(temp);
         Infobox.setText(DrawLine.getIbxText());
         Infobox.Refresh();
         break;

      case increase_wave_degree:

         if(ew_elem == false)
            break;
         temp = EW.getDegree();
         if(temp > 0)
            temp--;
         EW.setDegree(temp);
         Infobox.setText(EW.getIbxText());
         Infobox.Refresh();
         break;

      case decrease_wave_degree:

         if(ew_elem == false)
            break;
         temp = EW.getDegree();
         if(elem == Impulse)
            sz = ArrayRange(impulse_waves, 0) - 1;
         else
           {
            if(elem == ABC_correction || elem == ABCDE_correction)
               sz = ArrayRange(abcde_waves, 0) - 1;
            if(elem == WXY_correction || elem == WXYXZ_correction)
               sz = ArrayRange(wxyxz_waves, 0) - 1;
           }

         if(temp < sz)
            temp++;
         EW.setDegree(temp);
         Infobox.setText(EW.getIbxText());
         Infobox.Refresh();
         break;

      case change_font:

         if(ew_elem == false)
            break;
         temp = getFontIndex(EW.getFont());
         if(temp < ArraySize(wavefonts) - 1)
            temp++;
         else
            temp = 0;
         EW.setFont(wavefonts[temp]);
         Infobox.setFont(EW.getFont());
         Infobox.Refresh();
         break;

      case increase_fontsize:

         if(ew_elem == false)
            break;
         temp = EW.getFontsize();
         if(temp < max_fontsize)
            temp++;
         EW.setFontsize(temp);
         Infobox.setFontsize(EW.getFontsize());
         Infobox.Refresh();
         break;

      case decrease_fontsize:

         if(ew_elem == false)
            break;
         temp = EW.getFontsize();
         if(temp > min_fontsize)
            temp--;
         EW.setFontsize(temp);
         Infobox.setFontsize(EW.getFontsize());
         Infobox.Refresh();
         break;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              make_arrow()
  {
   long type;
   long selected;
   string name, arrowname;
   double p1, p2;
   int x1, x2, y1, y2, x, y, w = 0, length, length1, length2, temp, sign;
   long t1, t2;
   double angle, angle1;
   long colour;
   long width;

   for(int i = 0; i < ObjectsTotal(); i++)
     {
      name = ObjectName(i);
      type = ObjectGetInteger(0, name, OBJPROP_TYPE, 0);
      if(type == OBJ_TREND)
        {
         selected = ObjectGetInteger(0, name, OBJPROP_SELECTED, 0);

         if(selected == 1)
           {
            colour = ObjectGetInteger(0, name, OBJPROP_COLOR, 0);
            width = ObjectGetInteger(0, name, OBJPROP_WIDTH, 0);

            p1 = ObjectGetDouble(0, name, OBJPROP_PRICE1, 0);
            t1 = ObjectGetInteger(0, name, OBJPROP_TIME1, 0);
            p2 = ObjectGetDouble(0, name, OBJPROP_PRICE2, 0);
            t2 = ObjectGetInteger(0, name, OBJPROP_TIME2, 0);

            ChartTimePriceToXY(0, 0, t1, p1, x1, y1);
            ChartTimePriceToXY(0, 0, t2, p2, x2, y2);

            x = x2 - x1;
            y = y2 - y1;

            if(x > 0)
               sign = 1;
            else
               sign = -1;

            ChartTimePriceToXY(0, 0, iTime(NULL, 0, arrow_size), 0, length1, temp);
            ChartTimePriceToXY(0, 0, iTime(NULL, 0, 0), 0, length2, temp);

            length = length2 - length1;

            angle = MathArctan((double)y / (double) x);
            angle1 = M_PI * arrow_angle / 180;

            x = x2 - sign * (int)(length * MathCos(angle + angle1));
            y = y2 - sign * (int)(length * MathSin(angle + angle1));

            ChartXYToTimePrice(0, x, y, w, t1, p1);

            arrowname = LINESPREFIX + "arrow1" + (string) TimeLocal();
            ObjectCreate(0, arrowname, OBJ_TREND, 0, t2, p2, t1, p1);
            ObjectSetInteger(0, arrowname, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, arrowname, OBJPROP_COLOR, colour);
            ObjectSetInteger(0, arrowname, OBJPROP_RAY, 0);

            x = x2 - sign * (int)(length * MathCos(angle - angle1));
            y = y2 - sign * (int)(length * MathSin(angle - angle1));

            ChartXYToTimePrice(0, x, y, w, t1, p1);

            arrowname = LINESPREFIX + "arrow2" + (string) TimeLocal();
            ObjectCreate(0, arrowname, OBJ_TREND, 0, t2, p2, t1, p1);
            ObjectSetInteger(0, arrowname, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, arrowname, OBJPROP_COLOR, colour);
            ObjectSetInteger(0, arrowname, OBJPROP_RAY, 0);

            ObjectSetInteger(0, name, OBJPROP_SELECTED, 0);

           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              click_switcher(controls key)
  {
   if(ToggleModeOn == Yes && click_counter == 0)
      click_counter = 5;
   else
     {
      if(Control == key)
         click_counter = 0;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              manage_wave(action_keyword keyword)
  {
   string name, name2, label, ewfp, font;
   string ewfullprefixes[]; //to ensure that loop actions are not duplicated by the number of the elements selected within one wave
   bool duplication = false;
   int fontsize = 0, ewfp_count = 0, temp = 0, i = 0, j = 0, k = 0;
   color clr = Black;
   elements elem = 0;
   waveID ID = {false, 0, 0, NULL, 0, clrNONE};

   ArrayResize(ewfullprefixes, 1);

   for(i = 0; i < ObjectsTotal(); i++)
     {
      name = ObjectName(i);
      duplication = false;

      if(StringFind(name, EWPREFIX, 0) != -1 && ObjectGet(name, OBJPROP_SELECTED) == 1)
        {
         //--duplication check-----------
         ewfp = StringSubstr(name, 0, EWFULLPREFIXLEN);
         for(j = 0; j < ewfp_count; j++)
           {
            if(ewfullprefixes[j] == ewfp)
               duplication = true;
           }

         if(duplication == true)
            continue;

         ewfullprefixes[ewfp_count] = ewfp;
         ewfp_count++;
         ArrayResize(ewfullprefixes, ewfp_count + 1);
         //------------

         for(k = 0; k < ObjectsTotal(); k++)
           {
            name2 = ObjectName(k);

            if(StringFind(name2, ewfp, 0) != -1)
              {
               if(keyword == select_wave)//---------
                  ObjectSet(name2, OBJPROP_SELECTED, 1);

               if(keyword == increase_wave_degree || keyword == decrease_wave_degree) //---------------
                 {

                  elem = getElement(name2);
                  label = ObjectGetString(0, name2, OBJPROP_TEXT, 0);

                  if(getWavePos(label, elem).itiswave == true)
                    {
                     ID.itiswave = true;
                     ID.degree = getWavePos(label, elem).degree;
                     ID.count = getWavePos(label, elem).count;
                    }

                  if(keyword == increase_wave_degree)
                    {
                     ObjectSetString(0, name2, OBJPROP_TEXT, setWaveLabel(elem, ID.degree - 1, ID.count));
                    }

                  if(keyword == decrease_wave_degree)
                    {
                     ObjectSetString(0, name2, OBJPROP_TEXT, setWaveLabel(elem, ID.degree + 1, ID.count));
                    }
                 }

               if(keyword == increase_fontsize)
                 {
                  fontsize = (int)ObjectGet(name2, OBJPROP_FONTSIZE);
                  if(fontsize < max_fontsize)
                     fontsize++;
                  ObjectSet(name2, OBJPROP_FONTSIZE, fontsize);
                 }

               if(keyword == decrease_fontsize)
                 {
                  fontsize = (int)ObjectGet(name2, OBJPROP_FONTSIZE);
                  if(fontsize > min_fontsize)
                     fontsize--;
                  ObjectSet(name2, OBJPROP_FONTSIZE, fontsize);
                 }

               if(keyword == change_colour)
                 {
                  clr = (color)ObjectGetInteger(0, name2, OBJPROP_COLOR, 0);
                  temp = getColourIndex(clr, wavecolours);
                  if(temp >= ArraySize(wavecolours) - 1)
                     temp = 0;
                  else
                     temp = temp + 1;
                  ObjectSetInteger(0, name2, OBJPROP_COLOR, wavecolours[temp]);
                 }

               if(keyword == change_font)
                 {
                  font = ObjectGetString(0, name2, OBJPROP_FONT, 0);
                  temp = getFontIndex(font);
                  if(temp >= ArraySize(wavefonts) - 1)
                     temp = 0;
                  else
                     temp = temp + 1;
                  ObjectSetString(0, name2, OBJPROP_FONT, wavefonts[temp]);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              manage_line(action_keyword keyword)
  {
   string name = NULL;
   long temp = 0;
   color clr = Black;

   for(int i = 0; i < ObjectsTotal(); i++)
     {
      name = ObjectName(i);

      if(StringFind(name, LINESPREFIX, 0) != -1 && ObjectGet(name, OBJPROP_SELECTED) == 1)
        {
         if(keyword == unselect_line)
            ObjectSet(name, OBJPROP_SELECTED, 0);

         if(keyword == increase_width)
           {
            temp = ObjectGetInteger(0, name, OBJPROP_WIDTH, 0);
            if(temp < 100)
               temp++;
            ObjectSetInteger(0, name, OBJPROP_WIDTH, temp);
           }

         if(keyword == decrease_width)
           {
            temp = ObjectGetInteger(0, name, OBJPROP_WIDTH, 0);
            if(temp > 1)
               temp--;
            ObjectSetInteger(0, name, OBJPROP_WIDTH, temp);
           }

         if(keyword == change_style)
           {
            temp = ObjectGetInteger(0, name, OBJPROP_STYLE, 0);
            if(temp > 3)
               temp = 0;
            else
               temp++;
            ObjectSetInteger(0, name, OBJPROP_STYLE, temp);
           }

         if(keyword == change_colour)
           {
            clr = (color)ObjectGetInteger(0, name, OBJPROP_COLOR, 0);
            temp = getColourIndex(clr, linecolours);
            if(temp >= ArraySize(linecolours) - 1)
               temp = 0;
            else
               temp = temp + 1;
            ObjectSetInteger(0, name, OBJPROP_COLOR, linecolours[(int)temp]);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              AllWaves(action_keyword keyword)
  {
   string name;

   for(int i = 0; i < ObjectsTotal(); i++)
     {
      name = ObjectName(i);

      if(StringFind(name, EWPREFIX, 0) != -1)
        {
         if(keyword == select_wave)
            ObjectSet(name, OBJPROP_SELECTED, 1);

         if(keyword == unselect_wave)
            ObjectSet(name, OBJPROP_SELECTED, 0);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
waveID            getWavePos(string label, elements element)
  {

   int max = 0;
   waveID ID = {false, 0, 0, NULL, 0, clrNONE};

   switch(element)
     {
      case Dline:
         ID.itiswave = false;
         return ID;
         break;

      case Impulse:
         max = 9;
         for(int i = 0; i < max; i++)
           {
            for(int j = 0; j < 5; j++)
              {
               if(StringCompare(label, impulse_waves[i][j], true) == 0)
                 {
                  ID.itiswave = true;
                  ID.degree = i;
                  ID.count = j;
                  return ID;
                 }
              }
           }
         break;

      default:
         max = 6;
         for(int i = 0; i < max; i++)
           {
            for(int j = 0; j < 5; j++)
              {
               if(StringCompare(label, abcde_waves[i][j], true) == 0)
                 {
                  ID.itiswave = true;
                  ID.degree = i;
                  ID.count = j;
                  return ID;
                 }
               if(StringCompare(label, wxyxz_waves[i][j], true) == 0)
                 {
                  ID.itiswave = true;
                  ID.degree = i;
                  ID.count = j;
                  return ID;
                 }
              }
           }
         break;
     }

   ID.itiswave = false;
   return ID;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string            setWaveLabel(elements element, int degree, int count)
  {
   int dim = 0;

   switch(element)
     {
      case Dline:
         return "Dline";
         break;
      case Impulse:
         dim = ArrayRange(impulse_waves, 0);
         if(degree > dim - 1)
            return impulse_waves[dim - 1][count];
         if(degree < 0)
            return impulse_waves[0][count];
         return impulse_waves[degree][count];
         break;
      case ABC_correction:
         dim = ArrayRange(abcde_waves, 0);
         if(degree > dim - 1)
            return abcde_waves[dim - 1][count];
         if(degree < 0)
            return abcde_waves[0][count];
         return abcde_waves[degree][count];
         break;
      case ABCDE_correction:
         dim = ArrayRange(abcde_waves, 0);
         if(degree > dim - 1)
            return abcde_waves[dim - 1][count];
         if(degree < 0)
            return abcde_waves[0][count];
         return abcde_waves[degree][count];
         break;
      case WXY_correction:
         dim = ArrayRange(wxyxz_waves, 0);
         if(degree > dim - 1)
            return wxyxz_waves[dim - 1][count];
         if(degree < 0)
            return wxyxz_waves[0][count];
         return wxyxz_waves[degree][count];
         break;
      case WXYXZ_correction:
         dim = ArrayRange(wxyxz_waves, 0);
         if(degree > dim - 1)
            return wxyxz_waves[dim - 1][count];
         if(degree < 0)
            return wxyxz_waves[0][count];
         return wxyxz_waves[degree][count];
         break;
      default:
         return "Default";
         break;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
elements          getElement(string obj_name)
  {
   int elem = (int) StringSubstr(obj_name, EWFULLPREFIXLEN, 1);

   switch(elem)
     {
      case 0:
         return EmptyStart;
         break;
      case 1:
         return Dline;
         break;
      case 2:
         return Impulse;
         break;
      case 3:
         return ABC_correction;
         break;
      case 4:
         return ABCDE_correction;
         break;
      case 5:
         return WXY_correction;
         break;
      case 6:
         return WXYXZ_correction;
         break;
      case 7:
         return EmptyEnd;
         break;
      default:
         return EmptyStart;
         break;
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int               getColourIndex(color clrnow, color & set[])
  {
   for(int i = 0; i < ArraySize(set); i++)
     {
      if(clrnow == set[i])
         return i;
     }

   return 0;
  }
//+------------------------------------------------------------------+
int               getFontIndex(string font)
  {
   for(int i = 0; i < ArraySize(wavefonts); i++)
     {
      if(font == wavefonts[i])
         return i;
     }

   return 0;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void show_help()
  {

   if(help_toggle == true)
      Comment("\n ,(comma) to remove the indicator \n 1 to label 12345 wave \n A to label Abc wave\n E to label abcdE wave\n W to label Wxy wave\n",
              " Y to label wxYxz wave\n S to Select the wave of the selected label\n =(equality sign) to select all labels\n ESC to deselect all labels and lines \n Q to increase the wave degree\n",
              " SHIFT to decrease the wave degree\n X to increase the label size or line width\n Z to decrease the label size or line width\n C to cycle through Colors\n",
              " F to cycle through label Fonts or line styles\n 3 to reset the infobox wave to defaults\n D to Draw line\n V to to put arrow on the selected line\n",
              " ;(semi-colon) to select all lines\n R to Remove the wave of the selected label if quick removal is allowed\n tab/`(back quote)/space/win to effect drawing when Tab/BackQuote/Space/Winkey mode is on\n",
              " Any key except the above to effect drawing when AnyKey mode is on\n K to Kill and restart the indicator");
   else
      Comment("");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void delete_wave(elements el)
  {
   string name, nm, pr;
   int i = 0, j = 0;

   for(i = ObjectsTotal() - 1; i >= 0; i--)
     {
      name = ObjectName(i);

      if(StringFind(name, EWPREFIX, 0) == 0 && ObjectGet(name, OBJPROP_SELECTED) == 1)
        {
         pr = StringSubstr(name, 0, EWFULLPREFIXLEN);
        }

      for(j = ObjectsTotal(); j >= 0; j--)
        {
         nm = ObjectName(j);
         if(StringFind(nm, pr, 0) == 0)
           {
            ObjectDelete(nm);
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool selected_label_exists()
  {
   string name;

   for(int i = 0; i < ObjectsTotal(); i++)
     {
      name = ObjectName(i);
      if((StringFind(name, EWPREFIX, 0) == 0 || StringFind(name, LINESPREFIX, 0) == 0) && ObjectGetInteger(0, name, OBJPROP_SELECTED, 1))
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void hard_reset()
  {
   ImpulseWave.Reset(impulse_init_degree, Impulse);
   ABCWave.Reset(correction_init_degree, ABC_correction);
   ABCDEWave.Reset(correction_init_degree, ABCDE_correction);
   WXYWave.Reset(correction_init_degree, WXY_correction);
   WXYXZWave.Reset(correction_init_degree, WXYXZ_correction);
   DrawLine.Reset(Dline);
   Infobox.Reset();
  }
//+------------------------------------------------------------------+


ElliottWave* ew_pointer(elements elem)

  {

   ElliottWave* EW = &ImpulseWave;

   switch(elem)
     {
      case Impulse:
         EW = &ImpulseWave;
         break;
      case ABC_correction:
         EW = &ABCWave;
         break;
      case ABCDE_correction:
         EW = &ABCDEWave;
         break;
      case WXY_correction:
         EW = &WXYWave;
         break;
      case WXYXZ_correction:
         EW = &WXYXZWave;
         break;
      default:
         EW = &ImpulseWave;
         break;
     }

   return EW;

  }

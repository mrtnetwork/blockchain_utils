const Map<String, String> base64TestMap = {
  "": "",
  "L": "TA==",
  "\"D": "IkQ=",
  "Tg`": "VGdg",
  "!y{q": "IXl7cQ==",
  "#pmZ1": "I3BtWjE=",
  ";f*Sl{": "O2YqU2x7",
  "\raY\nW/v": "DWFZClcvdg==",
  "sM?tg?a_": "c00/dGc/YV8=",
  "XA6#EV}hr": "WEE2I0VWfWhy",
  "jJ'q%-b\\|R": "akoncSUtYlx8Ug==",
  "%q'[}U+#a25": "JXEnW31VKyNhMjU=",
  "\nC`CM{fPR/'k": "CkNgQ017ZlBSLydr",
  "sA*7r<XA}!lEO": "c0EqN3I8WEF9IWxFTw==",
  ".#P\n3 x^A1,I`F": "LiNQCjMgeF5BMSxJYEY=",
  "\tOk=jk,Z~\\STxAv": "CU9rPWprLFp+XFNUeEF2",
  "v(IN9Ssy'V,-B@!l": "dihJTjlTc3knViwtQkAhbA==",
  "2xt,.xU(lJgQCO1W5": "Mnh0LC54VShsSmdRQ08xVzU=",
  "bvitU*k#^\\bvJ9f/ip": "YnZpdFUqayNeXGJ2SjlmL2lw",
  "%V't?8k*4^J^ndg_@Y!": "JVYndD84ayo0XkpebmRnX0BZIQ==",
  "z{% /\\>'B2hX2Y3|{SG2": "enslIC9cPidCMmhYMlkzfHtTRzI=",
  "6@w11[yc^q~lxU_{),fKs": "NkB3MTFbeWNecX5seFVfeyksZktz",
  "*'Rdb\\RTLn\nh^2}fip%I *": "KidSZGJcUlRMbgpoXjJ9ZmlwJUkgKg==",
  "8KgX%Kgi<QmTN<ct\n.[?Cmk": "OEtnWCVLZ2k8UW1UTjxjdAouWz9DbWs=",
  "??N,sHJg1R!=WvWx,eX_B&Q{": "Pz9OLHNISmcxUiE9V3ZXeCxlWF9CJlF7",
  "\rhjP@Ag %0\tPR2%87[FP<;2n,": "DWhqUEBBZyAlMAlQUjIlODdbRlA8OzJuLA==",
  "k{o+6xE<UK{FiI!lXhu{\t&M8[8": "a3tvKzZ4RTxVS3tGaUkhbFhodXsJJk04Wzg=",
  "2U7d+Fm7 6L\r=13kH~X|\"~rUeA>": "MlU3ZCtGbTcgNkwNPTEza0h+WHwifnJVZUE+",
  "yl4q+B_cmhVNB.zz~\"`AQ`Q\\ztyb": "eWw0cStCX2NtaFZOQi56en4iYEFRYFFcenR5Yg==",
  "zIhoOqD=dn@3Y[x+8_ NA#W?T)CoA": "eklob09xRD1kbkAzWVt4KzhfIE5BI1c/VClDb0E=",
  "oX\"~#zP8^2{\\_c\n4eghz![lbMG7*J/":
      "b1gifiN6UDheMntcX2MKNGVnaHohW2xiTUc3Kkov",
  "{W u'BX|*@[.!%G%M%Vbc;PpgTFw. ,":
      "e1cgdSdCWHwqQFsuISVHJU0lVmJjO1BwZ1RGdy4gLA==",
  "l~]@TUbA?qN.}5#hJC.i31 >da(l>8^m":
      "bH5dQFRVYkE/cU4ufTUjaEpDLmkzMSA+ZGEobD44Xm0=",
  "\n[#%'25MJ?-2k<7,a.Fh4/<7m?^d\tF/G4":
      "ClsjJScyNU1KPy0yazw3LGEuRmg0Lzw3bT9eZAlGL0c0",
  "kR!68\\Xb6&\"7o,ujRW}Qel:D~{z/#&EXP6":
      "a1IhNjhcWGI2JiI3byx1alJXfVFlbDpEfnt6LyMmRVhQNg==",
  "@lHyjsUK:q271D_uCeS`9]\r-s{\nf\"E[CJFO":
      "QGxIeWpzVUs6cTI3MURfdUNlU2A5XQ0tc3sKZiJFW0NKRk8=",
  "^*RFwP\"@blL(ht7P_EACk6^[F~WBIwFM/?/>":
      "XipSRndQIkBibEwoaHQ3UF9FQUNrNl5bRn5XQkl3Rk0vPy8+",
  "_N1Xlz1>\"N\ragt#)ANY1W{+Li.NeR6+aH7t.i":
      "X04xWGx6MT4iTg1hZ3QjKUFOWTFXeytMaS5OZVI2K2FIN3QuaQ==",
  "A%44erZd:3p+6_- ,F'NxlWonc>QD;dE!2re%\\":
      "QSU0NGVyWmQ6M3ArNl8tICxGJ054bFdvbmM+UUQ7ZEUhMnJlJVw=",
  "=Dd281(d4\t+(8RC=Bk\\Ms.\nF,W-zuS-F:+)8K>\t":
      "PURkMjgxKGQ0CSsoOFJDPUJrXE1zLgpGLFctenVTLUY6Kyk4Sz4J",
  ")zWf8!lE=9dc-0fI{FXrN`Z-;QngbzD)MJZ[0bw]":
      "KXpXZjghbEU9OWRjLTBmSXtGWHJOYFotO1FuZ2J6RClNSlpbMGJ3XQ==",
  "n6W:q;9PI!\"\t.c|[i*<%kL\"9%FCd?L?:j^?vy Snh":
      "bjZXOnE7OVBJISIJLmN8W2kqPCVrTCI5JUZDZD9MPzpqXj92eSBTbmg=",
  "6~PvZ_\tj?Tc)~45ea U3j*Xos?T~GN.-j'p\rCqtMDu":
      "Nn5QdlpfCWo/VGMpfjQ1ZWEgVTNqKlhvcz9UfkdOLi1qJ3ANQ3F0TUR1",
  "B0JaZc6y~7~o(~=BHRe]PC^/C[Ex;.(LrZ>3@3s,0Q&":
      "QjBKYVpjNnl+N35vKH49QkhSZV1QQ14vQ1tFeDsuKExyWj4zQDNzLDBRJg==",
  "0y-PTT,n}y1pc].C\nkd {%C'bsY>9\nqY_?Z?JG6=b[b~":
      "MHktUFRULG59eTFwY10uQwprZCB7JUMnYnNZPjkKcVlfP1o/Skc2PWJbYn4=",
  "Cm?yM6]+=9nu,j3TpN=j/'~3I\nNEW;J\\d@yf9;ks'#?gK":
      "Q20/eU02XSs9OW51LGozVHBOPWovJ34zSQpORVc7SlxkQHlmOTtrcycjP2dL",
  "{1FtVgY}2.ji3\n*\\h]^g-D},b Aboa@z{{}j5J\\j|,GjCb":
      "ezFGdFZnWX0yLmppMwoqXGhdXmctRH0sYiBBYm9hQHp7e31qNUpcanwsR2pDYg==",
  "-vp\"U-h2ey1j/jShdF|C|f|Df\na{U4nf0O*l0hgA6\n\n2 YZ":
      "LXZwIlUtaDJleTFqL2pTaGRGfEN8ZnxEZgphe1U0bmYwTypsMGhnQTYKCjIgWVo=",
  "%S#`tZsIZtmc&0AOZ~ukfF/8%'t+Syx`_{|._bW\tn\r V\\(\ry":
      "JVMjYHRac0ladG1jJjBBT1p+dWtmRi84JSd0K1N5eGBfe3wuX2JXCW4NIFZcKA15",
  "5o%|hr@)=<ZlMKB]SjGt?Zds<Fs\n?jw,\\_LkaF:wq>r<.N7Ui":
      "NW8lfGhyQCk9PFpsTUtCXVNqR3Q/WmRzPEZzCj9qdyxcX0xrYUY6d3E+cjwuTjdVaQ==",
  "-!:}=uv\tsvyE&.6~rOg!*Ru\\jXqjO/HCa_.[K8X#QR<>q[?'`N":
      "LSE6fT11dglzdnlFJi42fnJPZyEqUnVcalhxak8vSENhXy5bSzhYI1FSPD5xWz8nYE4=",
  "DTBN-dR|+dM6tB.,xh}6,H3idlR\rHxRJD\\GT_o2c\rlkP\"bJfj``":
      "RFRCTi1kUnwrZE02dEIuLHhofTYsSDNpZGxSDUh4UkpEXEdUX28yYw1sa1AiYkpmamBg",
  "#6*{\rVEX_Jc*7Q'ZEOt%\r(E||~K~{M^pQtT.i(> 22obfx-!xY5'":
      "IzYqew1WRVhfSmMqN1EnWkVPdCUNKEV8fH5LfntNXnBRdFQuaSg+IDIyb2JmeC0heFk1Jw==",
  "amu]TXFtU|Jw-ALxd<\rTj=\"UHU`\r0}IHTffxOWRnRn9Lo{Eyv@Oxv":
      "YW11XVRYRnRVfEp3LUFMeGQ8DVRqPSJVSFVgDTB9SUhUZmZ4T1dSblJuOUxve0V5dkBPeHY=",
  "| F2xJv?YVh.r-L`OP6)\"?{FH|&]\"`\r.E\\&}vOMYVMGq}G g^OD2mJ":
      "fCBGMnhKdj9ZVmguci1MYE9QNikiP3tGSHwmXSJgDS5FXCZ9dk9NWVZNR3F9RyBnXk9EMm1K",
  "g7D'E_d_J!rC#_\"\\>`.`W_qy5')&\"827\"EZR>-WoyG+s\r%gw?1>ye!U":
      "ZzdEJ0VfZF9KIXJDI18iXD5gLmBXX3F5NScpJiI4MjciRVpSPi1Xb3lHK3MNJWd3PzE+eWUhVQ==",
  "<AhGTy.>-B*W-V_ '[RARg8=eh ~R )%O7!M5Dy6KKr\trSPm{)AQ}1\r@":
      "PEFoR1R5Lj4tQipXLVZfICdbUkFSZzg9ZWggflIgKSVPNyFNNUR5NktLcglyU1BteylBUX0xDUA=",
  "u'}pzC)~[%\t{qOs6u~0SA^ZL^e]+M\\Du^YTZ\nhsv8Hz\tqU=(UOyM+!Kk\n":
      "dSd9cHpDKX5bJQl7cU9zNnV+MFNBXlpMXmVdK01cRHVeWVRaCmhzdjhIeglxVT0oVU95TSshS2sK",
  "w(>Enw\\f\"](=0E1{_+Xtm%c+tak\rma8w[+l~yU\t\tai.@tb3U3*)oHP9~Am":
      "dyg+RW53XGYiXSg9MEUxe18rWHRtJWMrdGFrDW1hOHdbK2x+eVUJCWFpLkB0YjNVMyopb0hQOX5BbQ==",
  "\\T43Fb\"(g;)WDHPl!L3D/|X\nQ1Z]nGrt%kRGbHnK3 \rEp7OYOeIFx}a'\"F1":
      "XFQ0M0ZiIihnOylXREhQbCFMM0QvfFgKUTFaXW5HcnQla1JHYkhuSzMgDUVwN09ZT2VJRnh9YSciRjE=",
  "oG%~~ e/4Xfq{wmkv(h1rWK&<e%SnK^{&>P-b6+UnSA@3uKQ/6gPT.xj`|l^":
      "b0clfn4gZS80WGZxe3dta3YoaDFyV0smPGUlU25LXnsmPlAtYjYrVW5TQUAzdUtRLzZnUFQueGpgfGxe",
  "\t^&:mfhzPSKx0+S{m]H}@`&Fu{p?ONyJw_,M<|7!Uvf]{Qc7-&Qw\\?\tj{S\rd)":
      "CV4mOm1maHpQU0t4MCtTe21dSH1AYCZGdXtwP09OeUp3XyxNPHw3IVV2Zl17UWM3LSZRd1w/CWp7Uw1kKQ==",
  "I.]\\I5G^_CoA@^bySk/:ZEvY232Xke(A43:edj(M-vj|vh=J9u9@\\D`]-n.uzX":
      "SS5dXEk1R15fQ29BQF5ieVNrLzpaRXZZMjMyWGtlKEE0MzplZGooTS12anx2aD1KOXU5QFxEYF0tbi51elg=",
  "[rO)'^eosL(V7V8CQhdk`pe913K<#.hSj:La;-k\" ^M<`o[6vBL\"p]\\z_jV\"j\ty":
      "W3JPKSdeZW9zTChWN1Y4Q1FoZGtgcGU5MTNLPCMuaFNqOkxhOy1rIiBeTTxgb1s2dkJMInBdXHpfalYiagl5",
  "b:k\"_EF`y='X\n]c*smc.!z\"B*s-zP+9`1;\t9svEOb)ktQO`(%oy/04ixu?P9?{bk":
      "YjprIl9FRmB5PSdYCl1jKnNtYy4heiJCKnMtelArOWAxOwk5c3ZFT2Ipa3RRT2AoJW95LzA0aXh1P1A5P3tiaw==",
  "Ge'3!\"W^j;xZMf'\\#A&DmJBQ]\nyEAGI=~JI>],0_]u9;{m\tf\\q4&a9(2Q5X5lL8ve":
      "R2UnMyEiV15qO3haTWYnXCNBJkRtSkJRXQp5RUFHST1+Skk+XSwwX111OTt7bQlmXHE0JmE5KDJRNVg1bEw4dmU=",
  "t#:4ea/d\raVf6\r8xI>^,PKCU4B45Q=z%}cU'Uir(v.q3Memmp?{\"]vroIhnbQPSL<b":
      "dCM6NGVhL2QNYVZmNg04eEk+XixQS0NVNEI0NVE9eiV9Y1UnVWlyKHYucTNNZW1tcD97Il12cm9JaG5iUVBTTDxi",
  "ky}!%,u#\r0G@0)/xBl]QpI{4fM:Z%s@X:'aR+xU/j9EM+xG'e\\vOG9NcQdj#x#6)87(":
      "a3l9ISUsdSMNMEdAMCkveEJsXVFwSXs0Zk06WiVzQFg6J2FSK3hVL2o5RU0reEcnZVx2T0c5TmNRZGojeCM2KTg3KA==",
  "S|XMSewf,QjCq.,VN'.G+`CeNn*S?\n_6z' ^/{1\rzQ)N\"zf'4WMk`u)Ey))N5uY6?/1~":
      "U3xYTVNld2YsUWpDcS4sVk4nLkcrYENlTm4qUz8KXzZ6JyBeL3sxDXpRKU4iemYnNFdNa2B1KUV5KSlONXVZNj8vMX4=",
  "mVJ\rgK'9C}%_[~mOk5K.!% TtxWb\nio4on(@02A\t3_.,%NGy7jMODh#:412E [>0Ae<[1":
      "bVZKDWdLJzlDfSVfW35tT2s1Sy4hJSBUdHhXYgppbzRvbihAMDJBCTNfLiwlTkd5N2pNT0RoIzo0MTJFIFs+MEFlPFsx",
  " -j^}M5F][BQIza#A/yu|#N\nQpaI!(;ld[6LfbDu1]i|>**/! \tt5ZsW5<JnZU-ghr)o=0":
      "IC1qXn1NNUZdW0JRSXphI0EveXV8I04KUXBhSSEoO2xkWzZMZmJEdTFdaXw+KiovISAJdDVac1c1PEpuWlUtZ2hyKW89MA==",
  "ceM-},e\"{P?p;W\nx?]iu\t)1#<85U2}Gk }=6^xUPcoK`ksOa>.7R&316@M@j kJ,Tl)DrGJ":
      "Y2VNLX0sZSJ7UD9wO1cKeD9daXUJKTEjPDg1VTJ9R2sgfT02XnhVUGNvS2Brc09hPi43UiYzMTZATUBqIGtKLFRsKURyR0o=",
  "[\\0T7#`hi65v*vc_8)\t/\to\t|YWLu<x1[-r0\"paBwc^A_d~5%U{r\r-BgAq7 [KIo^e#Z5L~U~":
      "W1wwVDcjYGhpNjV2KnZjXzgpCS8Jbwl8WVdMdTx4MVstcjAicGFCd2NeQV9kfjUlVXtyDS1CZ0FxNyBbS0lvXmUjWjVMflV+",
  "L<Rw@k\"57&GW<1/L^Whjn.jXgDnyw-b#s_^:ck4z0uDSM*h*{FRApc?(3~F/h8k|hyg:Uf{P\"":
      "TDxSd0BrIjU3JkdXPDEvTF5XaGpuLmpYZ0RueXctYiNzX146Y2s0ejB1RFNNKmgqe0ZSQXBjPygzfkYvaDhrfGh5ZzpVZntQIg==",
  "y(yM6S\rNtnL*>zDE%wk5 \njcw9V9pq%]_4\tyc[y-fa7==VEB:=qHvF1ZoA}T5hxWg2lOx6)2=R":
      "eSh5TTZTDU50bkwqPnpERSV3azUgCmpjdzlWOXBxJV1fNAl5Y1t5LWZhNz09VkVCOj1xSHZGMVpvQX1UNWh4V2cybE94NikyPVI=",
  "H!GBgMR?\nXSmzLQNJ:c:=DF#b^l5FED(R?y1:\n7\\P_Q{{&\thi`g0Q@D\\\r,fz;cf{o04UTX^V-e8":
      "SCFHQmdNUj8KWFNtekxRTko6Yzo9REYjYl5sNUZFRChSP3kxOgo3XFBfUXt7JgloaWBnMFFARFwNLGZ6O2Nme28wNFVUWF5WLWU4",
  "eqfGo{C{|id[ceAo@);+h>x!/ZO|MfO0IE:7JT`^Z<nQedXAh_Sp!}1A\tjLj[(&y\"(NMA4(?5p[i":
      "ZXFmR297Q3t8aWRbY2VBb0ApOytoPnghL1pPfE1mTzBJRTo3SlRgXlo8blFlZFhBaF9TcCF9MUEJakxqWygmeSIoTk1BNCg/NXBbaQ==",
  "5ioEt\"9oWW-cY|rk7N=Al]\r>e1X;pO''MtMdQV?*\tYG\" O?0AXJN^IieYiH(?,-RWS.m\ts~mij] ;":
      "NWlvRXQiOW9XVy1jWXxyazdOPUFsXQ0+ZTFYO3BPJydNdE1kUVY/KglZRyIgTz8wQVhKTl5JaWVZaUgoPywtUldTLm0Jc35taWpdIDs=",
  "PnX5T l^gxSh%R}gr*'v~Z@JSLPF#gTZW<o51?Y0U<339]59~TrcD-n@n7=URs%f/ngul2OZU`5kpr":
      "UG5YNVQgbF5neFNoJVJ9Z3IqJ3Z+WkBKU0xQRiNnVFpXPG81MT9ZMFU8MzM5XTU5flRyY0QtbkBuNz1VUnMlZi9uZ3VsMk9aVWA1a3By",
  "!s*QZot\\M'jfB~!^GdAu\nz\t:\rVQx\r\\DmRS=xz<{Tz+S BZ~#t)\\*M/V!5hUCjplB)oP3#l/':]Vq@`i":
      "IXMqUVpvdFxNJ2pmQn4hXkdkQXUKegk6DVZReA1cRG1SUz14ejx7VHorUyBCWn4jdClcKk0vViE1aFVDanBsQilvUDMjbC8nOl1WcUBgaQ==",
  "KpS _is}e6z:74~IH)Z[]Rb,I9<d+74UqI,zJ\"w>zBIm\rt5g)p?@ZciaKgz\\j2uN.cKa*fp<B-1ZWYY|":
      "S3BTIF9pc31lNno6NzR+SUgpWltdUmIsSTk8ZCs3NFVxSSx6SiJ3PnpCSW0NdDVnKXA/QFpjaWFLZ3pcajJ1Ti5jS2EqZnA8Qi0xWldZWXw=",
  "Aq?3}>Y:P+`@<O\t1WpYVawjhWFypUE+8kLnya\n}^U`)P%&#Z{ s<~BpnLu\neXye;IjyvHgGn5h:Lf!\t_/":
      "QXE/M30+WTpQK2BAPE8JMVdwWVZhd2poV0Z5cFVFKzhrTG55YQp9XlVgKVAlJiNaeyBzPH5CcG5MdQplWHllO0lqeXZIZ0duNWg6TGYhCV8v",
  "}0TP}tpb(8L<uX_yy=?\\l=i`jEFsoT0+/R~HPt7X#Cb`JqI;1'CCGcW+!!ETe.<qBZQRRm\"Dj1wEa3)KOM":
      "fTBUUH10cGIoOEw8dVhfeXk9P1xsPWlgakVGc29UMCsvUn5IUHQ3WCNDYmBKcUk7MSdDQ0djVyshIUVUZS48cUJaUVJSbSJEajF3RWEzKUtPTQ==",
  "9B)=s[&\\@E1O!d~9*K((|GJY\\KZj\\j~Mm##V/<aU2`YVKT@/JEMU*lE//7F<*;Mp(ClL'![rW0n\n'hvBG,\\":
      "OUIpPXNbJlxARTFPIWR+OSpLKCh8R0pZXEtaalxqfk1tIyNWLzxhVTJgWVZLVEAvSkVNVSpsRS8vN0Y8KjtNcChDbEwnIVtyVzBuCidodkJHLFw=",
  "Zq=wgBZ-l-<ZFJjtDlfC*<}d-d3:N0/WkB(XqVK#C/?bC^=J^vFY.=yAhi:un>|e\n! (WkTW3)tf0n}M4I(K":
      "WnE9d2dCWi1sLTxaRkpqdERsZkMqPH1kLWQzOk4wL1drQihYcVZLI0MvP2JDXj1KXnZGWS49eUFoaTp1bj58ZQohIChXa1RXMyl0ZjBufU00SShL",
  "8Q0Dc#dO,p*m)Ig1>\\`sPPQcJMsk_C=mDD<oqj2\tl`(#1f\n8ASb?wK.ZEl\t?&ffy#`Gh%p:s^bF1vQ{x{j%`r":
      "OFEwRGMjZE8scCptKUlnMT5cYHNQUFFjSk1za19DPW1ERDxvcWoyCWxgKCMxZgo4QVNiP3dLLlpFbAk/JmZmeSNgR2glcDpzXmJGMXZRe3h7aiVgcg==",
  "|8UkU:MaM8,pcF;@UGO%*2}!z\t;(gmv0.VmLsJX~btN2u8]2DJ#FPY?`c{Pz:Zun@Zh\\_sbuiZ/>`Bls|R!;v6":
      "fDhVa1U6TWFNOCxwY0Y7QFVHTyUqMn0hegk7KGdtdjAuVm1Mc0pYfmJ0TjJ1OF0yREojRlBZP2Bje1B6Olp1bkBaaFxfc2J1aVovPmBCbHN8UiE7djY=",
  "!>Ji-I:HPhormW)x<[my,;fx(z;xPn\n_D7zA.\tM*i-7YtQmA u23f&{SK\"nn10+-);V@9.zxoDRZ\n|m6thL(^b=":
      "IT5KaS1JOkhQaG9ybVcpeDxbbXksO2Z4KHo7eFBuCl9EN3pBLglNKmktN1l0UW1BIHUyM2Yme1NLIm5uMTArLSk7VkA5Lnp4b0RSWgp8bTZ0aEwoXmI9",
  "r[B=<gz9_w`*[q!LtC2)K.!ouJLo%/GK}dVnpDmYfg.XT_^O7,@Ox1/s@YtD}\nb#Dm;p\nXQZy{KZVXkw&(/,Scj!":
      "cltCPTxnejlfd2AqW3EhTHRDMilLLiFvdUpMbyUvR0t9ZFZucERtWWZnLlhUX15PNyxAT3gxL3NAWXREfQpiI0RtO3AKWFFaeXtLWlZYa3cmKC8sU2NqIQ==",
  "/&EuD*=Zs5khaU!@,wsq{Co.urA)UeM|@8C):P\rkA\r] OGcFxXn~m9lx 0R4/ch4SvM3/(>,AZ\\@YbwVZ\t96j8JOA":
      "LyZFdUQqPVpzNWtoYVUhQCx3c3F7Q28udXJBKVVlTXxAOEMpOlANa0ENXSBPR2NGeFhufm05bHggMFI0L2NoNFN2TTMvKD4sQVpcQFlid1ZaCTk2ajhKT0E=",
  "*C\n@Z~(g'\\UE[iW[H\tS0vc^jn'JcbSUo;MXGq^'Z2p;xOSD4~R\\GS_'H=8SJ(q5!\n:iYCZ`{/3ohax]pD3 JW5H>_W":
      "KkMKQFp+KGcnXFVFW2lXW0gJUzB2Y15qbidKY2JTVW87TVhHcV4nWjJwO3hPU0Q0flJcR1NfJ0g9OFNKKHE1IQo6aVlDWmB7LzNvaGF4XXBEMyBKVzVIPl9X",
  " YStk)HQ3XbY2bl[]6#F}cDNX0}u@]'wM971qPP-9WVZjLQkVmBrg^.nXe8\\fY>}v{G,?-ic<{+Xz[QM3\r!j3R>Z{}Y":
      "IFlTdGspSFEzWGJZMmJsW102I0Z9Y0ROWDB9dUBdJ3dNOTcxcVBQLTlXVlpqTFFrVm1CcmdeLm5YZThcZlk+fXZ7Ryw/LWljPHsrWHpbUU0zDSFqM1I+Wnt9WQ==",
  "]UUO:3A3>j@vdes> qlMurR7gy.[!\nQ-5-j]#?[g.di-FMS\\0pQDo_s4kjX\n><w0YeR>2#fr=^f\r'p09~vL&)r\";11oP":
      "XVVVTzozQTM+akB2ZGVzPiBxbE11clI3Z3kuWyEKUS01LWpdIz9bZy5kaS1GTVNcMHBRRG9fczRralgKPjx3MFllUj4yI2ZyPV5mDSdwMDl+dkwmKXIiOzExb1A=",
  "F%HmSWXomep^Z2oQ\"e.G>xaj?@7o\nL\n*/@gI3X\\TkS~:6tx0X-KK}~2u.M&A-@3ZT`h>VA73)\tFl#`K3:9:*iy&\t]wbEx":
      "RiVIbVNXWG9tZXBeWjJvUSJlLkc+eGFqP0A3bwpMCiovQGdJM1hcVGtTfjo2dHgwWC1LS31+MnUuTSZBLUAzWlRgaD5WQTczKQlGbCNgSzM6OToqaXkmCV13YkV4",
  "~4rY~5fif:&m%:}>EC0W>2mdRU>Hv40Faz?R-;dF=Y@f>[R\t#ISx7kLT#nG;Ew2d[T;H8\rsw?gIyK=qMWX\tg*Ls1\nmo8+0":
      "fjRyWX41ZmlmOiZtJTp9PkVDMFc+Mm1kUlU+SHY0MEZhej9SLTtkRj1ZQGY+W1IJI0lTeDdrTFQjbkc7RXcyZFtUO0g4DXN3P2dJeUs9cU1XWAlnKkxzMQptbzgrMA==",
  "J6J tv\"f(\\o!>qm7Mgux@>h]}N\\-s+MD9kc;5uH-/H!A#_Q&Nc(I~\\u)x>3S,&r/6xDja{S`,Ud\tzs7-b7^V~\"#MCF\ny6p;":
      "SjZKIHR2ImYoXG8hPnFtN01ndXhAPmhdfU5cLXMrTUQ5a2M7NXVILS9IIUEjX1EmTmMoSX5cdSl4PjNTLCZyLzZ4RGphe1NgLFVkCXpzNy1iN15WfiIjTUNGCnk2cDs=",
  "|yvw]tZEr!/n`!b7{@N5'(RsZ`\\_-b|B\r\"oiDQ/u!9Q\rbjG~JKH%<n90+sJ)Nt.Zp>bTVu,=DFN~:{n|r5pGbQZzP;M^oN:3":
      "fHl2d110WkVyIS9uYCFiN3tATjUnKFJzWmBcXy1ifEINIm9pRFEvdSE5UQ1iakd+SktIJTxuOTArc0opTnQuWnA+YlRWdSw9REZOfjp7bnxyNXBHYlFaelA7TV5vTjoz",
  ">\"@[F%K(ck[noWK0 EZi:dF<w#Ou3I Qe )\\\nQ3gzl)|\\>dui,w'F/<G#DggMRC\r_oHGHX>h)O#e*j^2[\"%Cz=fg%4.-[v%K-":
      "PiJAW0YlSyhja1tub1dLMCBFWmk6ZEY8dyNPdTNJIFFlIClcClEzZ3psKXxcPmR1aSx3J0YvPEcjRGdnTVJDDV9vSEdIWD5oKU8jZSpqXjJbIiVDej1mZyU0Li1bdiVLLQ==",
  "N~1q|qxRHWI\"eI`'5PO?uIXXf}3AzkeC:=f}7|A\tvhNh9'01RT]Oht[!;j(xGz>#t~%'j(q\r~cwP'6ZkzeBGg+\rUJtB07@TJdT":
      "Tn4xcXxxeFJIV0kiZUlgJzVQTz91SVhYZn0zQXprZUM6PWZ9N3xBCXZoTmg5JzAxUlRdT2h0WyE7aih4R3o+I3R+JSdqKHENfmN3UCc2Wmt6ZUJHZysNVUp0QjA3QFRKZFQ=",
  "{} WApGW.;:Ge,X*#~5,FAc3iwBs'Te(38{g+7LF!@J!GI!U4v=Vt:tu\"gul Y!dur4Z\"hY57(6Fv-Ow.h{*.Qs-'x\\wN%B]5#H":
      "e30gV0FwR1cuOzpHZSxYKiN+NSxGQWMzaXdCcydUZSgzOHtnKzdMRiFASiFHSSFVNHY9VnQ6dHUiZ3VsIFkhZHVyNFoiaFk1Nyg2RnYtT3cuaHsqLlFzLSd4XHdOJUJdNSNI"
};

const Map<List<int>, String> specialBase64Map = {
  [0x00]: "AA==",
  [0x00, 0xff]: "AP8=",
  [0xff, 0x00, 0xff]: "/wD/",
  [0x01, 0x02, 0x03, 0x04]: "AQIDBA==",
  [0x10, 0x20, 0x30, 0x40]: "ECAwQA==",
};

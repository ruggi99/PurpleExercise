import{S as N,i as O,s as P,e as d,a as m,b as r,n as q,d as p,c as F,f as z,t as u,g as L,h as c,j as g}from"./index-6187c0a3.js";function B(o){let e;function t(l,f){return l[0].start_time!=0?H:G}let i=t(o),s=i(o);return{c(){s.c(),e=F()},m(l,f){s.m(l,f),r(l,e,f)},p(l,f){i===(i=t(l))&&s?s.p(l,f):(s.d(1),s=i(l),s&&(s.c(),s.m(e.parentNode,e)))},d(l){s.d(l),l&&p(e)}}}function G(o){let e;return{c(){e=d("h2"),e.textContent="La partita deve ancora cominciare",z(e,"text-align","center")},m(t,i){r(t,e,i)},p:q,d(t){t&&p(e)}}}function H(o){let e,t,i=o[0].points+"",s,l,f=o[0].initial_points+"",w,T,_,D,b,C,S,v,A,E,R,k,j,y,U,I;return{c(){e=d("p"),t=u("Score: "),s=u(i),l=u("/"),w=u(f),T=L(),_=d("p"),D=u("Progress: "),b=u(o[1]),C=u("%"),S=L(),v=d("p"),A=u("Time remained: "),E=u(o[2]),R=L(),k=d("div"),j=d("div"),y=d("div"),U=L(),I=d("p"),I.textContent=`Utente da mettere negli Enterprise Admin: ${{win_condition}}`,m(e,"class","score"),m(_,"class","progress"),m(v,"class","time"),m(y,"class","progress-value"),z(y,"width",o[1]+"%"),m(j,"id","progress"),m(j,"class","progress-full"),m(k,"class","progress-container"),z(k,"margin-bottom","10px"),m(I,"class","win_condition")},m(n,a){r(n,e,a),c(e,t),c(e,s),c(e,l),c(e,w),r(n,T,a),r(n,_,a),c(_,D),c(_,b),c(_,C),r(n,S,a),r(n,v,a),c(v,A),c(v,E),r(n,R,a),r(n,k,a),c(k,j),c(j,y),r(n,U,a),r(n,I,a)},p(n,a){a&1&&i!==(i=n[0].points+"")&&g(s,i),a&1&&f!==(f=n[0].initial_points+"")&&g(w,f),a&2&&g(b,n[1]),a&4&&g(E,n[2]),a&2&&z(y,"width",n[1]+"%")},d(n){n&&p(e),n&&p(T),n&&p(_),n&&p(S),n&&p(v),n&&p(R),n&&p(k),n&&p(U),n&&p(I)}}}function J(o){let e,t=o[0]!=null&&B(o);return{c(){e=d("div"),t&&t.c(),m(e,"class","box"),m(e,"data-color",o[3])},m(i,s){r(i,e,s),t&&t.m(e,null)},p(i,[s]){i[0]!=null?t?t.p(i,s):(t=B(i),t.c(),t.m(e,null)):t&&(t.d(1),t=null),s&8&&m(e,"data-color",i[3])},i:q,o:q,d(i){i&&p(e),t&&t.d()}}}const K=1e4,M=800;function Q(o,e,t){const i="";let s=null,l=0,f="",w="";async function T(){await(await fetch(i+"/data.json")).json()}async function _(){const b=await fetch(i+"/data.json");t(0,s=await b.json()),t(1,l=s.points*100/s.initial_points),l>60?t(3,w="green"):l>20?t(3,w="yellow"):t(3,w="red")}function D(){const b=new Date().getTime(),C=s.start_time==0?0:b/1e3-s.start_time,S=new Date(0).getTimezoneOffset(),v=s.max_seconds_available-C;t(2,f=new Date(v*1e3+S*60*1e3).toLocaleTimeString().substring(0,8))}return T().then(async()=>{await _(),D(),setInterval(_,K),setInterval(D,M)}),[s,l,f,w]}class V extends N{constructor(e){super(),O(this,e,Q,J,P,{})}}new V({target:document.getElementById("app")});
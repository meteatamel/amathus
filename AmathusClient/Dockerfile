FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
RUN BUILD_TS=$(date +%s) && \
    sed -i "s/flutter_bootstrap.js/flutter_bootstrap.js?v=${BUILD_TS}/g" /usr/share/nginx/html/index.html && \
    sed -i "s/main.dart.js/main.dart.js?v=${BUILD_TS}/g" /usr/share/nginx/html/flutter_bootstrap.js && \
    printf "'use strict';\nself.addEventListener('install',()=>{self.skipWaiting();});\nself.addEventListener('activate',(event)=>{event.waitUntil((async()=>{try{const keys=await caches.keys();await Promise.all(keys.map((k)=>caches.delete(k)));}catch(e){}try{await self.registration.unregister();}catch(e){}try{const clients=await self.clients.matchAll({type:'window'});clients.forEach((c)=>{if(c.url&&'navigate' in c){c.navigate(c.url);}});}catch(e){}})());});\n" > /usr/share/nginx/html/flutter_service_worker.js
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

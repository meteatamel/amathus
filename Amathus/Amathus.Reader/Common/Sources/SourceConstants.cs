﻿using System;

namespace Amathus.Reader.Common.Sources
{
    // TODO - Externalise these constants into a config file.

    public class SourceConstants
    {
        public static readonly Uri DetayKibris = new Uri("http://www.detaykibris.com/rss/");
        public static readonly Uri DetayKibrisLogo = new Uri("http://www.detaykibris.com/s/i/logo.png");

        public static readonly Uri Diyalog = new Uri("http://www.diyaloggazetesi.com/rss.php");
        public static readonly Uri DiyalogLogo = new Uri("http://www.diyaloggazetesi.com/images/banner/hslogo_1_1.png");

        public static readonly Uri GundemKibris = new Uri("http://www.gundemkibris.com/rss");
        public static readonly Uri GundemKibrisLogo = new Uri("https://www.gundemkibris.com/images/banner/analogo.png");

        public static readonly Uri HaberKibris = new Uri("http://haberkibris.com/rss.php");
        public static readonly Uri HaberKibrisLogo = new Uri("http://www.haberkibris.com/tplimages/logo.png");

        public static readonly Uri HalkinSesi = new Uri("http://www.halkinsesikibris.com/rss");
        public static readonly Uri HalkinSesiLogo = new Uri("http://www.halkinsesikibris.com/images/banner/HALKIN_SESI_CMYK_1.jpg");

        // Havadis has separate RSS feeds for different topics.
        public static readonly Uri Havadis = new Uri("http://www.havadiskibris.com/feed");
        public static readonly Uri HavadisLogo = new Uri("http://www.havadiskibris.com/wp-content/uploads/2016/04/havadisweblogo.jpg");

        public static readonly Uri KibrisAda = new Uri("http://www.kibrisadahaber.com/rss");
        public static readonly Uri KibrisAdaLogo = new Uri("http://www.kibrisadahaber.com/wp-content/uploads/2015/01/LOGO-kibrisadahaber_10.png");

        // KibrisPostasi has separate RSS feeds for different topics.
        public static readonly Uri KibrisPostasi = new Uri("http://www.kibrispostasi.com/rss.xml");
        public static readonly Uri KibrisPostasiLogo = new Uri("http://www.kibrispostasi.com/images/logo-tr.jpg");

        public static readonly Uri KibrisSonDakika = new Uri("http://kibrissondakika.com/feed");
        public static readonly Uri KibrisSonDakikaLogo = new Uri("http://www.kibrissondakika.com/wp-content/uploads/2015/09/logo.png");

        public static readonly Uri KibrisTime = new Uri("http://www.kibristime.com/rss.php");
        public static readonly Uri KibrisTimeLogo = new Uri("https://www.kibristime.com/images/banner/ktimepng_1.png");

        public static readonly Uri YeniCag = new Uri("http://www.ykp.org.cy/feed/");
        public static readonly Uri YeniCagLogo = new Uri("http://www.ykp.org.cy/wp-content/uploads/2018/04/ykp-544-180-400x133.jpg");

        // Yeniduzen has separate RSS feeds for different topics.
        public static readonly Uri YeniDuzen = new Uri("http://www.yeniduzen.com/rss");
        public static readonly Uri YeniDuzenLogo = new Uri("http://s.yeniduzen.com/i/logo.png");
 
        // TODO
        // GazeddaKibris
        // HaberalKibrisli - RSS has problems
        // KibrisGazetesi
        // KibrisManset - RSS has problems
    }
}

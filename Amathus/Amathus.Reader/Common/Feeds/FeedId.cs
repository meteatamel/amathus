namespace Amathus.Reader.Common.Feeds
{
    public enum FeedId
    {
        DemokratBakis,
        DetayKibris, 
        Diyalog, 
        GundemKibris, 
        HaberKibris, 
        HalkinSesi, 
        Havadis,
        KibrisAda,
        KibrisPostasi,
        KibrisSonDakika,
        KibrisTime,
        YeniCag,
        YeniDuzen,
    }

    public static class FeedIdExtensions
    {
        public static string ToFriendlyString(this FeedId me)
        {
            switch (me)
            {
                case FeedId.DemokratBakis:
                    return "Demokrat Bakış";
                case FeedId.DetayKibris:
                    return "Detay Kıbrıs";
                case FeedId.Diyalog:
                    return "Diyalog";
                case FeedId.GundemKibris:
                    return "Gündem Kıbrıs";
                case FeedId.HaberKibris:
                    return "Haber Kıbrıs";
                case FeedId.HalkinSesi:
                    return "Halkın Sesi";
                case FeedId.Havadis:
                    return "Havadis";
                case FeedId.KibrisAda:
                    return "Kıbrıs Ada";
                case FeedId.KibrisPostasi:
                    return "Kıbrıs Postası";
                case FeedId.KibrisSonDakika:
                    return "Kıbrıs Son Dakika";
                case FeedId.KibrisTime:
                    return "Kıbrıs Time";
                case FeedId.YeniCag:
                    return "Yeniçağ";
                case FeedId.YeniDuzen:
                    return "Yenidüzen";
            }
            return "";
        }
    }
}

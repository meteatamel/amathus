using System;

namespace Amathus.Reader.Common.Util
{
    public class DateTimeUtil
    {
        private static readonly TimeZoneInfo TurkeyTimeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById("Turkey Standard Time");
        private static readonly TimeSpan TurkeyUtcOffset = TurkeyTimeZoneInfo.GetUtcOffset(DateTime.Now);

        /// <summary>
        /// A DateTime with unspecified TimeZone is wrongly assumed to be in local TimeZone and gets converted 
        /// into UTC. This method takes that UTC DateTime, converts it back to local Timezone. Then, it forces
        /// into Turkish TimeZone before finally converting it back to UTC timezone.
        /// </summary>
        /// <param name="dateTime"></param>
        /// <returns></returns>
        public static DateTime FixToCorrectUtc(DateTime dateTime)
        {
            var local = TimeZoneInfo.ConvertTimeFromUtc(dateTime, TimeZoneInfo.Local);
            local = DateTime.SpecifyKind(local, DateTimeKind.Unspecified);
            var dateTimeOffset = new DateTimeOffset(local, TurkeyUtcOffset);
            return dateTimeOffset.UtcDateTime;
        }

        /// <summary>
        /// A DateTime is in specified UTC TimeZone but it's actually in Turkish Timezone.
        /// </summary>
        /// <param name="dateTime"></param>
        /// <returns></returns>
        public static DateTime FixIncorrectUtc(DateTime dateTime)
        {
            var dateTimeOffset = new DateTimeOffset(dateTime, TurkeyUtcOffset);
            return dateTimeOffset.UtcDateTime;
        }
    }
}

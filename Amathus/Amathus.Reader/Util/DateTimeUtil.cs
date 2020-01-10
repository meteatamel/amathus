// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
using System;

namespace Amathus.Reader.Util
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

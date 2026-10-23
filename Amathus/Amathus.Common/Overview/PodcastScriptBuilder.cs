// Copyright 2026 Google LLC
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
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace Amathus.Common.Overview
{
    public static class PodcastScriptBuilder
    {
        public static string ResolveEdition(DateTime? utcNow = null, string requestedEdition = null)
        {
            if (!string.IsNullOrWhiteSpace(requestedEdition))
            {
                var norm = requestedEdition.Trim().ToLowerInvariant();
                if (norm == "morning" || norm == "midday" || norm == "evening")
                {
                    return norm;
                }
            }

            var utc = utcNow ?? DateTime.UtcNow;
            // Cyprus time is UTC+2 in winter / UTC+3 in summer (EET/EEST)
            var cyprusHour = utc.AddHours(3).Hour;
            if (cyprusHour >= 5 && cyprusHour < 12)
            {
                return "morning";
            }
            if (cyprusHour >= 12 && cyprusHour < 17)
            {
                return "midday";
            }
            return "evening";
        }

        public static void EnsurePodcastPopulated(NewsOverview overview, string requestedEdition = null)
        {
            if (overview == null || overview.Stories == null || overview.Stories.Count == 0)
            {
                return;
            }

            var targetEdition = ResolveEdition(DateTime.UtcNow, requestedEdition);
            overview.Edition = targetEdition;
            if (overview.PodcastTurns == null || overview.PodcastTurns.Count < 6)
            {
                overview.PodcastTurns = BuildTurns(overview, targetEdition);
            }
        }

        public static List<PodcastDialogueTurn> BuildTurns(NewsOverview overview, string edition = null)
        {
            var resolvedEdition = ResolveEdition(overview?.GeneratedAt, edition);
            var stories = (overview?.Stories ?? new List<OverviewStory>())
                .Take(8)
                .ToList();

            var turns = new List<PodcastDialogueTurn>();
            if (stories.Count == 0)
            {
                return turns;
            }

            int turnIndex = 0;

            // Turn 0: Host A Opening Greeting & First Half of Quick Headline Rundown
            turns.Add(new PodcastDialogueTurn
            {
                Index = turnIndex++,
                Speaker = "A",
                StoryId = null,
                SpeakerNameEl = string.Empty,
                SpeakerNameTr = string.Empty,
                SpeakerNameEn = string.Empty,
                TextEl = BuildOpeningHostAEl(resolvedEdition, stories),
                TextTr = BuildOpeningHostATr(resolvedEdition, stories),
                TextEn = BuildOpeningHostAEn(resolvedEdition, stories)
            });

            // Turn 1: Host B Second Half of Quick Headline Rundown & Transition to Details
            turns.Add(new PodcastDialogueTurn
            {
                Index = turnIndex++,
                Speaker = "B",
                StoryId = stories[0].Id,
                SpeakerNameEl = string.Empty,
                SpeakerNameTr = string.Empty,
                SpeakerNameEn = string.Empty,
                TextEl = BuildOpeningHostBEl(stories),
                TextTr = BuildOpeningHostBTr(stories),
                TextEn = BuildOpeningHostBEn(stories)
            });

            // Story-by-story two-host conversation
            for (int i = 0; i < stories.Count; i++)
            {
                var story = stories[i];
                bool hostALeads = (i % 2 == 0);
                var leadSpeaker = hostALeads ? "A" : "B";
                var followSpeaker = hostALeads ? "B" : "A";

                turns.Add(new PodcastDialogueTurn
                {
                    Index = turnIndex++,
                    Speaker = leadSpeaker,
                    StoryId = story.Id,
                    SpeakerNameEl = string.Empty,
                    SpeakerNameTr = string.Empty,
                    SpeakerNameEn = string.Empty,
                    TextEl = BuildStoryLeadEl(story, i),
                    TextTr = BuildStoryLeadTr(story, i),
                    TextEn = BuildStoryLeadEn(story, i)
                });

                turns.Add(new PodcastDialogueTurn
                {
                    Index = turnIndex++,
                    Speaker = followSpeaker,
                    StoryId = story.Id,
                    SpeakerNameEl = string.Empty,
                    SpeakerNameTr = string.Empty,
                    SpeakerNameEn = string.Empty,
                    TextEl = BuildStoryFollowUpEl(story, i),
                    TextTr = BuildStoryFollowUpTr(story, i),
                    TextEn = BuildStoryFollowUpEn(story, i)
                });
            }

            // Closing Turn 1: Host A Wrap-up
            turns.Add(new PodcastDialogueTurn
            {
                Index = turnIndex++,
                Speaker = "A",
                StoryId = null,
                SpeakerNameEl = string.Empty,
                SpeakerNameTr = string.Empty,
                SpeakerNameEn = string.Empty,
                TextEl = BuildClosingHostAEl(),
                TextTr = BuildClosingHostATr(),
                TextEn = BuildClosingHostAEn()
            });

            // Closing Turn 2: Host B Sign-off
            turns.Add(new PodcastDialogueTurn
            {
                Index = turnIndex++,
                Speaker = "B",
                StoryId = null,
                SpeakerNameEl = string.Empty,
                SpeakerNameTr = string.Empty,
                SpeakerNameEn = string.Empty,
                TextEl = BuildClosingHostBEl(resolvedEdition),
                TextTr = BuildClosingHostBTr(resolvedEdition),
                TextEn = BuildClosingHostBEn(resolvedEdition)
            });

            return turns;
        }

        private static string BuildOpeningHostAEl(string edition, List<OverviewStory> stories)
        {
            var title = edition switch
            {
                "morning" => "Δικοινοτικές Ειδήσεις Κύπρου - Πρωινές Κύριες Ειδήσεις",
                "midday" => "Δικοινοτικές Ειδήσεις Κύπρου - Μεσημεριανές Κύριες Ειδήσεις",
                _ => "Δικοινοτικές Ειδήσεις Κύπρου - Βραδινές Κύριες Ειδήσεις"
            };
            var firstBatch = stories.Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleEl ?? s.TitleEn)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            var rundown = string.Join(" ", firstBatch);
            return $"Καλωσορίσατε στις {title}. Πριν περάσουμε στις λεπτομέρειες, ας δούμε συνοπτικά τους βασικούς τίτλους της επικαιρότητας: {rundown}";
        }

        private static string BuildOpeningHostATr(string edition, List<OverviewStory> stories)
        {
            var title = edition switch
            {
                "morning" => "Kıbrıs İki Toplumlu Haberler - Sabah Öne Çıkan Haberler",
                "midday" => "Kıbrıs İki Toplumlu Haberler - Öğle Öne Çıkan Haberler",
                _ => "Kıbrıs İki Toplumlu Haberler - Akşam Öne Çıkan Haberler"
            };
            var firstBatch = stories.Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleTr ?? s.TitleEn)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            var rundown = string.Join(" ", firstBatch);
            return $"{title} bültenine hoş geldiniz. Detaylara geçmeden önce günün öne çıkan başlıklarına hızlıca göz atalım: {rundown}";
        }

        private static string BuildOpeningHostAEn(string edition, List<OverviewStory> stories)
        {
            var title = edition switch
            {
                "morning" => "Cyprus Bicommunal News - Morning Top Stories",
                "midday" => "Cyprus Bicommunal News - Mid-Day Top Stories",
                _ => "Cyprus Bicommunal News - Evening Top Stories"
            };
            var firstBatch = stories.Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleEn ?? s.TitleTr)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            var rundown = string.Join(" ", firstBatch);
            return $"Welcome to {title}. Before we dive into the details, here is a quick rundown of our top headlines: {rundown}";
        }

        private static string BuildOpeningHostBEl(List<OverviewStory> stories)
        {
            var secondBatch = stories.Skip(3).Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleEl ?? s.TitleEn)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            if (secondBatch.Count > 0)
            {
                var rundown = string.Join(" ", secondBatch);
                return $"Επίσης στους σημερινούς τίτλους: {rundown} Ας περάσουμε τώρα αναλυτικά σε κάθε είδηση, ξεκινώντας από το πρώτο μας θέμα.";
            }
            return "Ας περάσουμε τώρα αναλυτικά σε κάθε είδηση, ξεκινώντας από το πρώτο μας θέμα.";
        }

        private static string BuildOpeningHostBTr(List<OverviewStory> stories)
        {
            var secondBatch = stories.Skip(3).Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleTr ?? s.TitleEn)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            if (secondBatch.Count > 0)
            {
                var rundown = string.Join(" ", secondBatch);
                return $"Gündemdeki diğer önemli başlıklarda ise: {rundown} Şimdi gelin bu gelişmelerin ayrıntılarına tek tek bakalım.";
            }
            return "Şimdi gelin bu gelişmelerin ayrıntılarına tek tek bakalım.";
        }

        private static string BuildOpeningHostBEn(List<OverviewStory> stories)
        {
            var secondBatch = stories.Skip(3).Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleEn ?? s.TitleTr)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            if (secondBatch.Count > 0)
            {
                var rundown = string.Join(" ", secondBatch);
                return $"Also making headlines right now: {rundown} Now let's take a closer look at each story one by one.";
            }
            return "Now let's take a closer look at each story one by one.";
        }

        private static string BuildStoryLeadEl(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "Ξεκινώντας με το πρώτο θέμα:",
                "Περνώντας στην επόμενη σημαντική είδηση:",
                "Ένα άλλο θέμα που απασχολεί έντονα την επικαιρότητα:",
                "Συνεχίζουμε με την επόμενη εξέλιξη:",
                "Στρέφουμε τώρα την προσοχή μας σε ένα ακόμη βασικό ζήτημα:",
                "Προχωρώντας στο επόμενο ρεπορτάζ της ημέρας:",
                "Σε μια άλλη σημαντική εξέλιξη:",
                "Και κλείνοντας την ανασκόπηση των ειδήσεων με το τελευταίο μας θέμα:"
            };

            var intro = transitions[Math.Min(index, transitions.Length - 1)];
            var title = EnsureEndPunctuation(CleanForSpeech(story.TitleEl ?? story.TitleEn));
            var (firstPart, _) = SplitNarrative(story.NarrativeEl ?? story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(firstPart))
            {
                return $"{intro} {title} {firstPart}";
            }
            return $"{intro} {title}";
        }

        private static string BuildStoryLeadTr(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "Günün ilk önemli gelişmesiyle başlıyoruz:",
                "Sıradaki öne çıkan başlığımıza geçelim:",
                "Bugün basında geniş yer bulan bir diğer önemli konu:",
                "Gündemdeki bir sonraki gelişmeyle devam edelim:",
                "Ada basınında dikkat çeken bir başka başlık ise şöyle:",
                "Bültenimizin sıradaki haberine baktığımızda:",
                "Öne çıkan bir diğer gelişmede:",
                "Ve bugünkü haber turumuzun son başlığına gelirken:"
            };

            var intro = transitions[Math.Min(index, transitions.Length - 1)];
            var title = EnsureEndPunctuation(CleanForSpeech(story.TitleTr ?? story.TitleEn));
            var (firstPart, _) = SplitNarrative(story.NarrativeTr ?? story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(firstPart))
            {
                return $"{intro} {title} {firstPart}";
            }
            return $"{intro} {title}";
        }

        private static string BuildStoryLeadEn(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "Leading our briefing today:",
                "Turning now to our next major story:",
                "Another headline drawing strong attention today:",
                "Moving on to the next key development:",
                "Next up, let's look at another story making waves on the island:",
                "Continuing with the next story of our briefing:",
                "In another notable development today:",
                "And for the final story of this briefing:"
            };

            var intro = transitions[Math.Min(index, transitions.Length - 1)];
            var title = EnsureEndPunctuation(CleanForSpeech(story.TitleEn ?? story.TitleTr));
            var (firstPart, _) = SplitNarrative(story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(firstPart))
            {
                return $"{intro} {title} {firstPart}";
            }
            return $"{intro} {title}";
        }

        private static string BuildStoryFollowUpEl(OverviewStory story, int index)
        {
            var reactions = new[]
            {
                "Πράγματι.",
                "Ακριβώς, και έχει ενδιαφέρον πώς εξελίσσεται το ζήτημα.",
                "Πολύ σωστά.",
                "Είναι όντως ένα κομβικό θέμα.",
                "Αξίζει να σταθούμε ιδιαίτερα εδώ.",
                "Σωστά, και οι λεπτομέρειες έχουν ιδιαίτερη σημασία."
            };
            var reaction = reactions[index % reactions.Length];

            var title = CleanForSpeech(story.TitleEl ?? story.TitleEn);
            var (_, secondPart) = SplitNarrative(story.NarrativeEl ?? story.NarrativeEn, title);
            var sourcesSummary = BuildSourcesCommentaryEl(story);

            if (!string.IsNullOrWhiteSpace(secondPart))
            {
                return $"{reaction} {secondPart} {sourcesSummary}".Trim();
            }
            return $"{reaction} {sourcesSummary}".Trim();
        }

        private static string BuildStoryFollowUpTr(OverviewStory story, int index)
        {
            var reactions = new[]
            {
                "Kesinlikle.",
                "Çok doğru, konunun yansımaları da oldukça dikkat çekici.",
                "Evet, detaylara baktığımızda tablo daha da netleşiyor.",
                "Gerçekten önemli bir gelişme.",
                "Burada altı çizilmesi gereken önemli noktalar var.",
                "Aynen öyle."
            };
            var reaction = reactions[index % reactions.Length];

            var title = CleanForSpeech(story.TitleTr ?? story.TitleEn);
            var (_, secondPart) = SplitNarrative(story.NarrativeTr ?? story.NarrativeEn, title);
            var sourcesSummary = BuildSourcesCommentaryTr(story);

            if (!string.IsNullOrWhiteSpace(secondPart))
            {
                return $"{reaction} {secondPart} {sourcesSummary}".Trim();
            }
            return $"{reaction} {sourcesSummary}".Trim();
        }

        private static string BuildStoryFollowUpEn(OverviewStory story, int index)
        {
            var reactions = new[]
            {
                "That's right.",
                "Indeed, and the wider context around this is important.",
                "Spot on.",
                "It really is a key development.",
                "There's an important angle to highlight here.",
                "Exactly, and the details behind the story matter."
            };
            var reaction = reactions[index % reactions.Length];

            var title = CleanForSpeech(story.TitleEn ?? story.TitleTr);
            var (_, secondPart) = SplitNarrative(story.NarrativeEn, title);
            var sourcesSummary = BuildSourcesCommentaryEn(story);

            if (!string.IsNullOrWhiteSpace(secondPart))
            {
                return $"{reaction} {secondPart} {sourcesSummary}".Trim();
            }
            return $"{reaction} {sourcesSummary}".Trim();
        }

        private static string BuildSourcesCommentaryEl(OverviewStory story)
        {
            var sources = story.Sources ?? new List<OverviewStorySource>();
            var langs = sources.Select(s => (s.FeedLanguage ?? "").ToLowerInvariant()).Distinct().ToList();

            if (langs.Count >= 2)
            {
                return "Το θέμα συγκεντρώνει διακοινοτικό ενδιαφέρον, αναδεικνύοντας τη σημασία του σε ολόκληρο το νησί.";
            }
            return "Οι εξελίξεις παρακολουθούνται στενά, με έμφαση στις επόμενες κινήσεις.";
        }

        private static string BuildSourcesCommentaryTr(OverviewStory story)
        {
            var sources = story.Sources ?? new List<OverviewStorySource>();
            var langs = sources.Select(s => (s.FeedLanguage ?? "").ToLowerInvariant()).Distinct().ToList();

            if (langs.Count >= 2)
            {
                return "Bu gelişme ada genelinde ortak gündem olarak yakından takip ediliyor.";
            }
            return "Konunun önümüzdeki günlerdeki etkileri kamuoyu tarafından dikkatle izleniyor.";
        }

        private static string BuildSourcesCommentaryEn(OverviewStory story)
        {
            var sources = story.Sources ?? new List<OverviewStorySource>();
            var langs = sources.Select(s => (s.FeedLanguage ?? "").ToLowerInvariant()).Distinct().ToList();

            if (langs.Count >= 2)
            {
                return "We're seeing cross-community attention on this story, underscoring its island-wide impact.";
            }
            return "The situation continues to unfold and remains a key focus today.";
        }

        private static string BuildClosingHostAEl()
        {
            return "Αυτές ήταν οι Κύριες Ειδήσεις της Κύπρου για αυτή την ώρα. Μπορείτε να πατήσετε σε οποιαδήποτε είδηση παρακάτω για να διαβάσετε ολόκληρα τα άρθρα.";
        }

        private static string BuildClosingHostATr()
        {
            return "Kıbrıs Öne Çıkan Haberler bültenimizin sonuna geldik. Aşağıdaki haber kartlarına dokunarak tüm makaleleri detaylı olarak okuyabilirsiniz.";
        }

        private static string BuildClosingHostAEn()
        {
            return "And that wraps up our Cyprus Top Stories briefing. You can tap any story card below to read the full articles.";
        }

        private static string BuildClosingHostBEl(string edition)
        {
            var wish = edition switch
            {
                "morning" => "Καλή συνέχεια στην ημέρα σας!",
                "midday" => "Καλό απόγευμα σε όλους!",
                _ => "Καλό σας βράδυ!"
            };
            return $"Σας ευχαριστούμε που μας ακούσατε. Θα είμαστε ξανά μαζί σας στην επόμενη έκδοση. {wish}";
        }

        private static string BuildClosingHostBTr(string edition)
        {
            var wish = edition switch
            {
                "morning" => "Herkese güzel bir gün diliyoruz, hoşça kalın!",
                "midday" => "Bir sonraki bültende görüşmek üzere, iyi günler!",
                _ => "Bir sonraki bültende buluşmak dileğiyle, iyi akşamlar!"
            };
            return $"Bizi dinlediğiniz için teşekkürler. {wish}";
        }

        private static string BuildClosingHostBEn(string edition)
        {
            var wish = edition switch
            {
                "morning" => "Have a wonderful morning, and see you in our Mid-Day edition!",
                "midday" => "Enjoy the rest of your afternoon, and join us again this evening!",
                _ => "Have a great evening, and we'll see you tomorrow morning!"
            };
            return $"Thanks for listening — {wish}";
        }

        private static (string FirstPart, string SecondPart) SplitNarrative(string rawNarrative, string headline)
        {
            if (string.IsNullOrWhiteSpace(rawNarrative))
            {
                return (string.Empty, string.Empty);
            }

            var cleaned = CleanForSpeech(rawNarrative);

            var sentences = Regex.Split(cleaned, @"(?<=[\.\!\?])\s+")
                .Select(s => StripSourceReportPrefix(s.Trim()))
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Where(s => !IsBoilerplateCoverageSentence(s))
                .Where(s => !IsDuplicateOfHeadline(s, headline))
                .ToList();

            if (sentences.Count == 0)
            {
                return (string.Empty, string.Empty);
            }

            if (sentences.Count == 1)
            {
                return (EnsureEndPunctuation(sentences[0]), string.Empty);
            }

            var first = EnsureEndPunctuation(sentences[0]);
            var second = EnsureEndPunctuation(string.Join(" ", sentences.Skip(1).Take(2)));
            return (first, second);
        }

        private static bool IsBoilerplateCoverageSentence(string sentence)
        {
            var lower = sentence.ToLowerInvariant();
            return lower.StartsWith("covered by ") ||
                   lower.StartsWith("reported by ") ||
                   lower.Contains("tarafından kapsanmaktadır") ||
                   lower.Contains("tarafından bildirildi") ||
                   lower.StartsWith("καλύπτεται από");
        }

        private static bool IsDuplicateOfHeadline(string sentence, string headline)
        {
            if (string.IsNullOrWhiteSpace(headline))
            {
                return false;
            }
            var normSentence = Regex.Replace(sentence.ToLowerInvariant(), @"[^\p{L}\p{N}]+", "");
            var normHeadline = Regex.Replace(headline.ToLowerInvariant(), @"[^\p{L}\p{N}]+", "");
            if (string.IsNullOrEmpty(normSentence) || string.IsNullOrEmpty(normHeadline))
            {
                return false;
            }
            return normSentence == normHeadline || normHeadline.Contains(normSentence);
        }

        private static string CleanForSpeech(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }
            var cleaned = Regex.Replace(text, @"<.*?>", " ");
            cleaned = System.Net.WebUtility.HtmlDecode(cleaned);
            // Strip parenthetical media tags like (VIDEO), (ΦΩΤΟ), (VİDEO), (ΒΙΝΤΕΟ)
            cleaned = Regex.Replace(cleaned, @"\((?:VIDEO|ΒΙΝΤΕΟ|ΦΩΤΟ|ΦΩΤΟΣ|VİDEO|FOTO|PHOTO|PHOTOS|PICTURES)[^\)]*\)", "", RegexOptions.IgnoreCase);
            cleaned = Regex.Replace(cleaned, @"\s+", " ").Trim();
            return StripSourceReportPrefix(cleaned);
        }

        private static string StripSourceReportPrefix(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }
            return Regex.Replace(
                text.Trim(),
                @"^[^:\.]{2,35}\s+(reports|αναφέρει|bildiriyor|haberi)\s*:\s*",
                "",
                RegexOptions.IgnoreCase).Trim();
        }

        private static string EnsureEndPunctuation(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }
            var t = text.Trim();
            if (t.EndsWith(".") || t.EndsWith("!") || t.EndsWith("?") || t.EndsWith(";"))
            {
                return t;
            }
            return t + ".";
        }
    }
}

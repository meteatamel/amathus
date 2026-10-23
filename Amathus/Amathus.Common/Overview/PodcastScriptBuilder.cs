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
            if (overview.PodcastTurns == null ||
                overview.PodcastTurns.Count < 6 ||
                (overview.PodcastTurns.Count > 2 && string.IsNullOrWhiteSpace(overview.PodcastTurns[2]?.StoryId)))
            {
                overview.PodcastTurns = BuildTurns(overview, targetEdition);
                return;
            }

            // Ensure StoryId is populated on story turns (turns 2 .. N-3)
            var topStories = overview.Stories.Take(8).ToList();
            for (int i = 0; i < overview.PodcastTurns.Count; i++)
            {
                var turn = overview.PodcastTurns[i];
                if (turn == null) continue;
                if (i < 2 || i >= overview.PodcastTurns.Count - 2)
                {
                    turn.StoryId = null;
                }
                else
                {
                    int storyIdx = (i - 2) / 2;
                    if (storyIdx >= 0 && storyIdx < topStories.Count)
                    {
                        turn.StoryId = topStories[storyIdx].Id;
                    }
                }
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
                StoryId = null,
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
                "morning" => "Δικοινοτικές Ειδήσεις Κύπρου - Πρωί",
                "midday" => "Δικοινοτικές Ειδήσεις Κύπρου - Μεσημέρι",
                _ => "Δικοινοτικές Ειδήσεις Κύπρου - Βράδυ"
            };
            var firstBatch = stories.Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleEl ?? s.TitleEn)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            var rundown = string.Join(" ", firstBatch);
            return $"Γεια σας φίλοι μας και καλωσορίσατε στις {title}! Πάρτε τον καφέ σας κι ελάτε να δούμε μαζί τι συζητιέται σήμερα σε όλο το νησί. Ξεκινάμε με μια γρήγορη ματιά στους πρώτους τίτλους: {rundown}";
        }

        private static string BuildOpeningHostATr(string edition, List<OverviewStory> stories)
        {
            var title = edition switch
            {
                "morning" => "Kıbrıs İki Toplumlu Haberler - Sabah",
                "midday" => "Kıbrıs İki Toplumlu Haberler - Öğle",
                _ => "Kıbrıs İki Toplumlu Haberler - Akşam"
            };
            var firstBatch = stories.Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleTr ?? s.TitleEn)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            var rundown = string.Join(" ", firstBatch);
            return $"Herkese merhaba! {title} bültenimize hoş geldiniz. Kahvenizi alın, gelin bugün adanın iki yakasında neler konuşuluyor hızlıca bir bakalım: {rundown}";
        }

        private static string BuildOpeningHostAEn(string edition, List<OverviewStory> stories)
        {
            var title = edition switch
            {
                "morning" => "Cyprus Bicommunal News - Morning",
                "midday" => "Cyprus Bicommunal News - Mid-Day",
                _ => "Cyprus Bicommunal News - Evening"
            };
            var firstBatch = stories.Take(3)
                .Select(s => EnsureEndPunctuation(CleanForSpeech(s.TitleEn ?? s.TitleTr)))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();
            var rundown = string.Join(" ", firstBatch);
            return $"Hey everyone, welcome back to {title}! Grab a coffee and settle in — here is a quick look at what is everyone talking about across the island right now: {rundown}";
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
                return $"Και δεν είναι μόνο αυτά! Στην επικαιρότητα ξεχωρίζουν επίσης: {rundown} Πάμε λοιπόν να τα δούμε ένα-ένα πιο χαλαρά και αναλυτικά, ξεκινώντας από το πρώτο μας θέμα.";
            }
            return "Πάμε λοιπόν να τα δούμε ένα-ένα πιο χαλαρά και αναλυτικά, ξεκινώντας από το πρώτο μας θέμα.";
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
                return $"Aynen öyle, gündem bugün oldukça hareketli! Öne çıkan diğer başlıklarda ise şunlar var: {rundown} Hadi gelin ilk haberimizle sohbete başlayalım.";
            }
            return "Hadi gelin ilk haberimizle sohbete başlayalım.";
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
                return $"Yeah, plenty happening today! Also catching our eye right now: {rundown} Let's jump right in and unpack each story one by one.";
            }
            return "Let's jump right in and unpack each story one by one.";
        }

        private static string BuildStoryLeadEl(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "Λοιπόν, ας ξεκινήσουμε με το θέμα που βρίσκεται στην πρώτη γραμμή σήμερα:",
                "Πάμε τώρα στο επόμενο θέμα που συζητιέται πολύ:",
                "Και περνώντας σε κάτι που επίσης τραβάει τα βλέμματα σήμερα:",
                "Συνεχίζοντας την κουβέντα μας, ας δούμε κι αυτή την εξέλιξη:",
                "Ένα άλλο θέμα που απασχολεί έντονα τις εφημερίδες στο νησί είναι το εξής:",
                "Ας ρίξουμε τώρα μια ματιά στην επόμενη ιστορία της ημέρας:",
                "Παράλληλα, έχουμε και μια ακόμη ενδιαφέρουσα είδηση:",
                "Και για το κλείσιμο της σημερινής μας βόλτας στις ειδήσεις:"
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
                "İlk olarak bugün herkesin konuştuğu şu gelişmeyle başlayalım:",
                "Şimdi geçelim gündemde çok konuşulan bir diğer konuya:",
                "Bu arada gazetelerde dikkat çeken bir başka önemli başlık da şu:",
                "Sohbetimize sıradaki gelişmeyle devam edelim:",
                "Ada genelinde merakla takip edilen bir diğer haber ise şöyle:",
                "Gelin şimdi bugünün bir diğer önemli başlığına bakalım:",
                "Öte yandan gözden kaçmaması gereken bir gelişme daha var:",
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
                "So kicking things off today, let's talk about our top story:",
                "Now, shifting gears to another big story everyone's talking about:",
                "Meanwhile, here's another headline catching plenty of attention today:",
                "Moving along, let's check out what's happening with our next story:",
                "Another topic making waves across the island's papers today is this one:",
                "Next up, let's take a look at another development worth watching:",
                "On another note, here's a story that's also drawing focus today:",
                "And wrapping up our rundown with one final story:"
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
                "Έτσι ακριβώς, κι αυτό που έχει ιδιαίτερο ενδιαφέρον εδώ είναι το παρασκήνιο.",
                "Πραγματικά, και αξίζει να δούμε πώς αποτυπώνεται αυτό στον Τύπο.",
                "Πολύ σωστά, γιατί οι λεπτομέρειες κάνουν τη διαφορά.",
                "Ακριβώς, πρόκειται για ένα θέμα που αγγίζει πολύ κόσμο.",
                "Ναι, κι εδώ φαίνεται ξεκάθαρα γιατί το θέμα συζητιέται τόσο έντονα.",
                "Σωστά, κι αν δούμε τη συνολική εικόνα, έχει μεγάλη σημασία."
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
                "Kesinlikle, işin en dikkat çekici tarafı da zaten burası.",
                "Çok doğru, üstelik basındaki yansımalarına baktığımızda tablo daha da netleşiyor.",
                "Tam da öyle, detaylar gerçekten çok önemli.",
                "Gerçekten de bugün üzerinde en çok durulan konulardan biri bu.",
                "Evet, burada altı çizilmesi gereken çok önemli bir nokta var.",
                "Aynen öyle, büyük resme baktığımızda etkisi oldukça geniş."
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
                "Yeah, totally — and what really stands out here is the bigger picture.",
                "Right, and when you look at how the papers are covering it, there's a lot to unpack.",
                "Spot on, the details behind this one really matter.",
                "Exactly, it's definitely one of those stories everyone is keeping an eye on.",
                "For sure, and there's an interesting angle to highlight here too.",
                "Yeah, that's such a key point."
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
                return "Είναι μάλιστα χαρακτηριστικό ότι το θέμα απασχολεί έντονα και τις δύο κοινότητες σε ολόκληρο το νησί.";
            }
            return "Θα έχει σίγουρα μεγάλο ενδιαφέρον να δούμε πώς θα εξελιχθεί τις επόμενες μέρες.";
        }

        private static string BuildSourcesCommentaryTr(OverviewStory story)
        {
            var sources = story.Sources ?? new List<OverviewStorySource>();
            var langs = sources.Select(s => (s.FeedLanguage ?? "").ToLowerInvariant()).Distinct().ToList();

            if (langs.Count >= 2)
            {
                return "Üstelik bu konunun adanın her iki kesiminde de yakından takip edilmesi ne kadar önemli olduğunu gösteriyor.";
            }
            return "Önümüzdeki günlerde bu başlığın nasıl şekilleneceğini hep birlikte göreceğiz.";
        }

        private static string BuildSourcesCommentaryEn(OverviewStory story)
        {
            var sources = story.Sources ?? new List<OverviewStorySource>();
            var langs = sources.Select(s => (s.FeedLanguage ?? "").ToLowerInvariant()).Distinct().ToList();

            if (langs.Count >= 2)
            {
                return "It's getting strong attention across both communities too, which really shows how much it matters island-wide.";
            }
            return "Definitely a story we'll be watching closely as things develop over the coming days.";
        }

        private static string BuildClosingHostAEl()
        {
            return "Και κάπου εδώ ολοκληρώσαμε τη σημερινή μας ανασκόπηση! Αν θέλετε να διαβάσετε περισσότερα, απλώς πατήστε σε οποιαδήποτε κάρτα είδησης παρακάτω για να δείτε ολόκληρα τα άρθρα.";
        }

        private static string BuildClosingHostATr()
        {
            return "Böylece bugünkü öne çıkan haber turumuzun sonuna geldik! Merak ettiğiniz haberlerin tamamını okumak için aşağıdaki kartlara dokunmanız yeterli.";
        }

        private static string BuildClosingHostAEn()
        {
            return "And that brings us to the end of today's roundup! If any story caught your ear, just tap on its card right below to read the full coverage.";
        }

        private static string BuildClosingHostBEl(string edition)
        {
            return edition switch
            {
                "morning" => "Σας ευχαριστούμε πολύ για την παρέα! Τα λέμε ξανά στη Μεσημεριανή μας έκδοση — να έχετε ένα υπέροχο πρωινό!",
                "midday" => "Σας ευχαριστούμε πολύ για την παρέα! Ανανεώνουμε το ραντεβού μας για τη Βραδινή μας έκδοση — καλό απόγευμα σε όλους!",
                _ => "Σας ευχαριστούμε πολύ για την παρέα! Τα λέμε πάλι αύριο στην Πρωινή μας έκδοση — καλό σας βράδυ!"
            };
        }

        private static string BuildClosingHostBTr(string edition)
        {
            return edition switch
            {
                "morning" => "Bize katıldığınız için çok teşekkürler! Öğle bültenimizde yeniden buluşmak üzere, herkese harika bir sabah diliyoruz!",
                "midday" => "Bize katıldığınız için çok teşekkürler! Akşam bültenimizde yeniden görüşmek üzere, keyifli bir gün geçirmeniz dileğiyle!",
                _ => "Bize katıldığınız için çok teşekkürler! Yarın Sabah bültenimizde yeniden buluşmak üzere, herkese iyi akşamlar!"
            };
        }

        private static string BuildClosingHostBEn(string edition)
        {
            return edition switch
            {
                "morning" => "Thanks so much for hanging out with us — have an awesome morning, and catch you again for our Mid-Day edition!",
                "midday" => "Thanks so much for tuning in — enjoy the rest of your afternoon, and we'll catch you back here for the Evening edition!",
                _ => "Thanks so much for listening — have a relaxing evening, and we'll catch you again tomorrow for our Morning edition!"
            };
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

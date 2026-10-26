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

        private static readonly Regex GreekScriptRegex = new(@"[\u0370-\u03FF\u1F00-\u1FFF]", RegexOptions.Compiled);
        private static readonly Regex TurkishSpecificRegex = new(@"[ğĞşŞıİ]", RegexOptions.Compiled);
        private static readonly Regex EnglishCommonWordsRegex = new(@"\b(the|and|to|of|in|is|are|was|were|for|with|on|that|this|we|our|from|as|at|by|about|into|over|after)\b", RegexOptions.IgnoreCase | RegexOptions.Compiled);
        private static readonly Regex LatinLongPhraseRegex = new(@"(?:[A-Za-zÀ-ÖØ-öø-ÿğĞşŞıİçÇöÖüÜ]{3,}\s+){5,}[A-Za-zÀ-ÖØ-öø-ÿğĞşŞıİçÇöÖüÜ]{3,}", RegexOptions.Compiled);
        private static readonly Regex LegacyPhraseRegex = new(@"(Grab a coffee and settle in|Yeah,\s*totally|across the island right now)", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        public static bool HasMixedOrUntranslatedTurns(List<PodcastDialogueTurn> turns)
        {
            if (turns == null || turns.Count < 6)
            {
                return true;
            }

            foreach (var turn in turns)
            {
                if (turn == null)
                {
                    return true;
                }

                var tr = turn.TextTr ?? string.Empty;
                var en = turn.TextEn ?? string.Empty;
                var el = turn.TextEl ?? string.Empty;

                if (string.IsNullOrWhiteSpace(tr) || string.IsNullOrWhiteSpace(en) || string.IsNullOrWhiteSpace(el))
                {
                    return true;
                }

                // Turkish or English turns should never contain Greek script
                if (GreekScriptRegex.IsMatch(tr) || GreekScriptRegex.IsMatch(en))
                {
                    return true;
                }

                // English turns should only be rejected for Turkish characters if they lack English structure
                // (proper nouns like "Erhan Arıklı" or "Lefkoşa" in English sentences are fine)
                if (TurkishSpecificRegex.IsMatch(en) && !EnglishCommonWordsRegex.IsMatch(en))
                {
                    return true;
                }

                // Greek turns must contain Greek script and not contain long untranslated Latin sentences
                if (!GreekScriptRegex.IsMatch(el) || LatinLongPhraseRegex.IsMatch(el))
                {
                    return true;
                }
            }

            // Also rebuild if the script still uses legacy repetitive template phrases
            if (turns.Any(t => t != null && LegacyPhraseRegex.IsMatch(t.TextEn ?? string.Empty)))
            {
                return true;
            }

            return false;
        }

        public static bool EnsurePodcastPopulated(NewsOverview overview, string requestedEdition = null, bool forceRebuild = false)
        {
            if (overview == null || overview.Stories == null || overview.Stories.Count == 0)
            {
                return false;
            }

            var previousEdition = overview.Edition?.Trim().ToLowerInvariant();
            var targetEdition = ResolveEdition(DateTime.UtcNow, requestedEdition);
            bool editionChanged = !string.IsNullOrWhiteSpace(previousEdition) &&
                                  !string.Equals(previousEdition, targetEdition, StringComparison.OrdinalIgnoreCase);
            overview.Edition = targetEdition;
            if (forceRebuild ||
                editionChanged ||
                overview.PodcastTurns == null ||
                overview.PodcastTurns.Count < 6 ||
                (overview.PodcastTurns.Count > 2 && string.IsNullOrWhiteSpace(overview.PodcastTurns[2]?.StoryId)) ||
                HasMixedOrUntranslatedTurns(overview.PodcastTurns))
            {
                overview.PodcastTurns = BuildTurns(overview, targetEdition);
                return true;
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
            return false;
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
            int variant = Math.Abs((overview?.GeneratedAt.DayOfYear ?? 0) + stories.Count) % 3;

            // Turn 0: Host A Opening Greeting & Conversational Theme Intro
            turns.Add(new PodcastDialogueTurn
            {
                Index = turnIndex++,
                Speaker = "A",
                StoryId = null,
                SpeakerNameEl = string.Empty,
                SpeakerNameTr = string.Empty,
                SpeakerNameEn = string.Empty,
                TextEl = BuildOpeningHostAEl(resolvedEdition, overview, stories, variant),
                TextTr = BuildOpeningHostATr(resolvedEdition, overview, stories, variant),
                TextEn = BuildOpeningHostAEn(resolvedEdition, overview, stories, variant)
            });

            // Turn 1: Host B Conversational Follow-up & Transition to First Story
            turns.Add(new PodcastDialogueTurn
            {
                Index = turnIndex++,
                Speaker = "B",
                StoryId = null,
                SpeakerNameEl = string.Empty,
                SpeakerNameTr = string.Empty,
                SpeakerNameEn = string.Empty,
                TextEl = BuildOpeningHostBEl(stories, variant),
                TextTr = BuildOpeningHostBTr(stories, variant),
                TextEn = BuildOpeningHostBEn(stories, variant)
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

        private static string BuildOpeningHostAEl(string edition, NewsOverview overview, List<OverviewStory> stories, int variant)
        {
            var title = edition switch
            {
                "morning" => "Δικοινοτικές Ειδήσεις Κύπρου - Πρωί",
                "midday" => "Δικοινοτικές Ειδήσεις Κύπρου - Μεσημέρι",
                _ => "Δικοινοτικές Ειδήσεις Κύπρου - Βράδυ"
            };

            var greeting = edition switch
            {
                "morning" => variant switch
                {
                    0 => $"Καλημέρα σας και καλωσορίσατε στις {title}! Καθώς ξεκινά η μέρα μας, ελάτε να δούμε μαζί τις βασικές εξελίξεις που διαμορφώνουν τη σημερινή επικαιρότητα.",
                    1 => $"Γεια σας φίλοι μας και καλωσορίσατε στις {title}! Πάρτε τον πρωινό σας καφέ κι ελάτε να συζητήσουμε όσα ξεχωρίζουν σήμερα στην επικαιρότητα.",
                    _ => $"Καλημέρα σε όλους, είστε συντονισμένοι στις {title}! Ελάτε να κάνουμε μια πρώτη βόλτα στα θέματα που συζητιούνται περισσότερο σήμερα."
                },
                "midday" => variant switch
                {
                    0 => $"Γεια σας και καλωσορίσατε στις {title}! Ώρα για ένα μικρό μεσημεριανό διάλειμμα για να δούμε πώς εξελίσσονται τα σημαντικότερα θέματα της ημέρας.",
                    1 => $"Καλό μεσημέρι φίλοι μας και καλωσορίσατε στις {title}! Η επικαιρότητα τρέχει από το πρωί, οπότε ελάτε να δούμε τι βρίσκεται στο προσκήνιο αυτή την ώρα.",
                    _ => $"Χαίρετε και καλωσορίσατε στις {title}! Στη μέση της ημέρας, ας ρίξουμε μια ματιά στις βασικές εξελίξεις που απασχολούν την ειδησεογραφία."
                },
                _ => variant switch
                {
                    0 => $"Καλησπέρα σας και καλωσορίσατε στις {title}! Καθώς κλείνει η μέρα, ελάτε να δούμε μαζί τις πιο σημαντικές εξελίξεις που ξεχώρισαν σήμερα.",
                    1 => $"Γεια σας φίλοι μας και καλωσορίσατε στις {title}! Στο τέλος μιας γεμάτης ημέρας, ας συζητήσουμε τα θέματα που άφησαν το αποτύπωμά τους.",
                    _ => $"Καλησπέρα σε όλους και καλωσορίσατε στις {title}! Ελάτε να κάνουμε έναν χαλαρό απολογισμό με τις κυριότερες ιστορίες της σημερινής ημέρας."
                }
            };

            var summary = CleanForSpeech(overview?.SummaryEl);
            if (!string.IsNullOrWhiteSpace(summary) && GreekScriptRegex.IsMatch(summary))
            {
                return $"{greeting} {EnsureEndPunctuation(summary)}";
            }

            var clauses = stories.Take(2)
                .Select(s => ToConversationalClause(s.TitleEl ?? s.TitleEn))
                .Where(c => !string.IsNullOrWhiteSpace(c))
                .ToList();
            if (clauses.Count == 2)
            {
                return $"{greeting} Σήμερα η συζήτηση περιστρέφεται γύρω από {clauses[0]}, αλλά και {clauses[1]}.";
            }
            if (clauses.Count == 1)
            {
                return $"{greeting} Σήμερα η συζήτηση επικεντρώνεται σε {clauses[0]}.";
            }
            return greeting;
        }

        private static string BuildOpeningHostATr(string edition, NewsOverview overview, List<OverviewStory> stories, int variant)
        {
            var title = edition switch
            {
                "morning" => "Kıbrıs İki Toplumlu Haberler - Sabah",
                "midday" => "Kıbrıs İki Toplumlu Haberler - Öğle",
                _ => "Kıbrıs İki Toplumlu Haberler - Akşam"
            };

            var greeting = edition switch
            {
                "morning" => variant switch
                {
                    0 => $"Günaydın, {title} bültenimize hoş geldiniz! Güne başlarken bugünün gündemini şekillendiren gelişmeleri gelin birlikte konuşalım.",
                    1 => $"Herkese merhaba ve günaydın! {title} bültenindeyiz. Sabah kahveniz hazırsa bugünün öne çıkan konularına birlikte göz atalım.",
                    _ => $"Selamlar, {title} yayınına hoş geldiniz! Yeni günde nelerin konuşulduğunu ve hangi gelişmelerin öne çıktığını birlikte değerlendirelim."
                },
                "midday" => variant switch
                {
                    0 => $"Herkese merhaba, {title} bültenimize hoş geldiniz! Gün ortasında kısa bir mola verip şu ana kadar öne çıkan gelişmeleri birlikte ele alalım.",
                    1 => $"İyi günler! {title} yayınındayız. Sabahtan bu yana oldukça hareketli bir gündem var; gelin detaylara birlikte bakalım.",
                    _ => $"Selamlar ve iyi öğleden sonralar! {title} bülteninde günün bu saatine kadar yaşanan önemli gelişmeleri konuşacağız."
                },
                _ => variant switch
                {
                    0 => $"İyi akşamlar, {title} bültenimize hoş geldiniz! Günü tamamlarken bugün en çok konuşulan gelişmeleri gelin birlikte değerlendirelim.",
                    1 => $"Herkese merhaba ve iyi akşamlar! {title} yayınındayız. Yoğun geçen günün ardından öne çıkan haberlerin detaylarına birlikte bakalım.",
                    _ => $"Selamlar, {title} bültenine hoş geldiniz! Günün yorgunluğunu atarken bugüne damga vuran konuları sohbet havasında ele alalım."
                }
            };

            var summary = CleanForSpeech(overview?.SummaryTr);
            if (!string.IsNullOrWhiteSpace(summary) && !GreekScriptRegex.IsMatch(summary))
            {
                return $"{greeting} {EnsureEndPunctuation(summary)}";
            }

            var clauses = stories.Take(2)
                .Select(s => ToConversationalClause(s.TitleTr ?? s.TitleEn))
                .Where(c => !string.IsNullOrWhiteSpace(c))
                .ToList();
            if (clauses.Count == 2)
            {
                return $"{greeting} Bugün özellikle {clauses[0]} konusu ve bunun yanı sıra {clauses[1]} gündemin ilk sıralarında yer alıyor.";
            }
            if (clauses.Count == 1)
            {
                return $"{greeting} Bugün özellikle {clauses[0]} konusu gündemin ilk sırasında yer alıyor.";
            }
            return greeting;
        }

        private static string BuildOpeningHostAEn(string edition, NewsOverview overview, List<OverviewStory> stories, int variant)
        {
            var title = edition switch
            {
                "morning" => "Cyprus Bicommunal News - Morning",
                "midday" => "Cyprus Bicommunal News - Mid-Day",
                _ => "Cyprus Bicommunal News - Evening"
            };

            var greeting = edition switch
            {
                "morning" => variant switch
                {
                    0 => $"Good morning and welcome to {title}! As you're getting your day started, let's walk through the key stories shaping today's agenda.",
                    1 => $"Hey everyone, welcome back to {title}! If you have your morning coffee handy, settle in as we talk through what's making news early today.",
                    _ => $"Hello and welcome to {title}! Great to have you with us this morning as we get you caught up on today's biggest developments."
                },
                "midday" => variant switch
                {
                    0 => $"Hello and welcome to {title}! Hope your day is going well — if you're taking a midday break, let's catch up on how today's big stories are unfolding.",
                    1 => $"Hey everyone, welcome back to {title}! Plenty has been developing since this morning, so let's take a few minutes to talk through what's in focus right now.",
                    _ => $"Welcome to {title}! As we hit the middle of the day, let's get you up to speed on the major conversations and developments so far."
                },
                _ => variant switch
                {
                    0 => $"Good evening and welcome to {title}! As you wind down for the day, let's look back at the major stories and developments that shaped today's news.",
                    1 => $"Hey everyone, welcome back to {title}! Thanks for spending part of your evening with us as we unpack the biggest topics from today.",
                    _ => $"Hello and welcome to {title}! As the day wraps up, let's talk through the key developments and stories everyone has been following today."
                }
            };

            var summary = CleanForSpeech(overview?.SummaryEn);
            if (!string.IsNullOrWhiteSpace(summary) && EnglishCommonWordsRegex.IsMatch(summary))
            {
                return $"{greeting} {EnsureEndPunctuation(summary)}";
            }

            var clauses = stories.Take(2)
                .Select(s => ToConversationalClauseEn(s.TitleEn ?? s.TitleTr))
                .Where(c => !string.IsNullOrWhiteSpace(c))
                .ToList();
            if (clauses.Count == 2)
            {
                return $"{greeting} Today we're following {clauses[0]}, along with {clauses[1]}.";
            }
            if (clauses.Count == 1)
            {
                return $"{greeting} Leading our conversation today is {clauses[0]}.";
            }
            return greeting;
        }

        private static string BuildOpeningHostBEl(List<OverviewStory> stories, int variant)
        {
            var extraClauses = stories.Skip(2).Take(2)
                .Select(s => ToConversationalClause(s.TitleEl ?? s.TitleEn))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();

            if (extraClauses.Count == 2)
            {
                return $"Πραγματικά έχουμε πολλά να συζητήσουμε σήμερα. Παράλληλα θα δούμε τι συμβαίνει με {extraClauses[0]}, καθώς και {extraClauses[1]}. Πάμε λοιπόν να τα πάρουμε από την αρχή.";
            }
            if (extraClauses.Count == 1)
            {
                return $"Πραγματικά έχουμε πολλά να πούμε σήμερα, ενώ θα σταθούμε επίσης σε {extraClauses[0]}. Πάμε λοιπόν να ξεκινήσουμε με το πρώτο μας θέμα.";
            }
            return "Πάμε λοιπόν να δούμε αναλυτικά όλες τις εξελίξεις, ξεκινώντας από το πρώτο μας θέμα.";
        }

        private static string BuildOpeningHostBTr(List<OverviewStory> stories, int variant)
        {
            var extraClauses = stories.Skip(2).Take(2)
                .Select(s => ToConversationalClause(s.TitleTr ?? s.TitleEn))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();

            if (extraClauses.Count == 2)
            {
                return $"Kesinlikle, bugün konuşacak çok şey var. Ayrıca {extraClauses[0]} ile ilgili gelişmeleri ve {extraClauses[1]} konusunu da ele alacağız. Hadi ilk konuyla sohbete başlayalım.";
            }
            if (extraClauses.Count == 1)
            {
                return $"Kesinlikle, gündem oldukça yoğun. Bu arada {extraClauses[0]} konusuna da değineceğiz. Hadi ilk gelişmeyle başlayalım.";
            }
            return "Hadi gelin öne çıkan gelişmeleri tek tek konuşmaya başlayalım.";
        }

        private static string BuildOpeningHostBEn(List<OverviewStory> stories, int variant)
        {
            var extraClauses = stories.Skip(2).Take(2)
                .Select(s => ToConversationalClauseEn(s.TitleEn ?? s.TitleTr))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .ToList();

            var leadIn = variant switch
            {
                0 => "There is plenty to unpack today.",
                1 => "It's a busy news cycle for sure.",
                _ => "Lots of important developments to get through."
            };

            if (extraClauses.Count == 2)
            {
                return $"{leadIn} We'll also be looking into {extraClauses[0]}, as well as {extraClauses[1]}. Let's dive right in and take them one by one.";
            }
            if (extraClauses.Count == 1)
            {
                return $"{leadIn} We'll also touch on {extraClauses[0]}. Let's dive right in and unpack the details.";
            }
            return $"{leadIn} Let's dive right in and unpack each story one by one.";
        }

        private static string BuildStoryLeadEl(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "Ας ξεκινήσουμε λοιπόν με το θέμα που βρίσκεται στην πρώτη γραμμή σήμερα.",
                "Περνώντας τώρα στο επόμενο θέμα, έχουμε μια εξέλιξη που συζητιέται έντονα.",
                "Ας δούμε τώρα τι συμβαίνει σε ένα άλλο μέτωπο της επικαιρότητας.",
                "Συνεχίζοντας την κουβέντα μας, υπάρχει μια ακόμη υπόθεση που ξεχωρίζει.",
                "Ένα άλλο ζήτημα που απασχολεί τις σημερινές συζητήσεις έχει επίσης μεγάλο ενδιαφέρον.",
                "Ας στρέψουμε τώρα την προσοχή μας στην επόμενη ιστορία της ημέρας.",
                "Παράλληλα, αξίζει να σταθούμε σε μια ακόμη εξέλιξη.",
                "Και για το κλείσιμο της σημερινής μας ανασκόπησης, ας δούμε το τελευταίο μας θέμα."
            };

            var intro = transitions[Math.Min(index, transitions.Length - 1)];
            var title = EnsureEndPunctuation(CleanForSpeech(story.TitleEl ?? story.TitleEn));
            var (firstPart, _) = SplitNarrative(story.NarrativeEl ?? story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(firstPart))
            {
                return $"{intro} {firstPart}";
            }
            return $"{intro} {EnsureEndPunctuation(ToConversationalClause(title))}";
        }

        private static string BuildStoryLeadTr(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "İlk olarak bugün gündemin ilk sırasındaki gelişmeyle başlayalım.",
                "Şimdi geçelim bugün çok konuşulan bir diğer önemli konuya.",
                "Bu arada gündemin bir başka dikkat çeken başlığına da değinelim.",
                "Sohbetimize sıradaki önemli gelişmeyle devam edelim.",
                "Bugün yakından takip edilen bir diğer konu da oldukça dikkat çekici.",
                "Gelin şimdi bir diğer önemli gelişmenin detaylarına bakalım.",
                "Öte yandan gözden kaçmaması gereken bir haber daha var.",
                "Ve bugünkü turumuzun son konusuna gelirken şu gelişmeye de bakalım."
            };

            var intro = transitions[Math.Min(index, transitions.Length - 1)];
            var title = EnsureEndPunctuation(CleanForSpeech(story.TitleTr ?? story.TitleEn));
            var (firstPart, _) = SplitNarrative(story.NarrativeTr ?? story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(firstPart))
            {
                return $"{intro} {firstPart}";
            }
            return $"{intro} {EnsureEndPunctuation(ToConversationalClause(title))}";
        }

        private static string BuildStoryLeadEn(OverviewStory story, int index)
        {
            var transitions = new[]
            {
                "Let's start with the biggest development leading the agenda today.",
                "Turning to our next topic, there's another major story unfolding.",
                "Meanwhile, another issue is drawing quite a bit of discussion today.",
                "Shifting gears a bit, let's look at what's happening on another front.",
                "Moving along, there is another important development making news today.",
                "Next up, let's take a look at a story that has been building up recently.",
                "On another note, here is a development that's also getting attention.",
                "And to wrap up our main stories today, let's look at this final development."
            };

            var intro = transitions[Math.Min(index, transitions.Length - 1)];
            var title = EnsureEndPunctuation(CleanForSpeech(story.TitleEn ?? story.TitleTr));
            var (firstPart, _) = SplitNarrative(story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(firstPart))
            {
                return $"{intro} {firstPart}";
            }
            return $"{intro} {EnsureEndPunctuation(ToConversationalClauseEn(title))}";
        }

        private static string BuildStoryFollowUpEl(OverviewStory story, int index)
        {
            var reactions = new[]
            {
                "Κι αν δούμε πιο προσεκτικά το παρασκήνιο, καταλαβαίνουμε γιατί προκαλεί τόσες αντιδράσεις.",
                "Πράγματι, και αξίζει να δούμε πώς αποτυπώνεται αυτό στα σημερινά ρεπορτάζ.",
                "Εδώ ακριβώς είναι που οι λεπτομέρειες κάνουν όλη τη διαφορά.",
                "Πρόκειται άλλωστε για ένα ζήτημα με άμεσο αντίκτυπο στην καθημερινότητα.",
                "Και βλέποντας τις αντιδράσεις, φαίνεται ξεκάθαρα πόσο κρίσιμο είναι το θέμα.",
                "Αυτό που έχει ιδιαίτερη σημασία εδώ είναι η συνέχεια της υπόθεσης.",
                "Τα επιπλέον στοιχεία βοηθούν πολύ στο να δούμε τη συνολική εικόνα.",
                "Είναι σίγουρα μια εξέλιξη που δείχνει πώς διαμορφώνεται το κλίμα."
            };
            var reaction = reactions[index % reactions.Length];

            var title = CleanForSpeech(story.TitleEl ?? story.TitleEn);
            var (_, secondPart) = SplitNarrative(story.NarrativeEl ?? story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(secondPart))
            {
                return $"{reaction} {secondPart}".Trim();
            }
            return $"{reaction} {BuildSourcesCommentaryEl(story, index)}".Trim();
        }

        private static string BuildStoryFollowUpTr(OverviewStory story, int index)
        {
            var reactions = new[]
            {
                "İşin arka planına baktığımızda neden bu kadar yankı uyandırdığını görmek zor değil.",
                "Üstelik basındaki yansımalarına baktığımızda tablo daha da netleşiyor.",
                "Buradaki detaylar sürecin nereye evrileceğini anlamak açısından çok önemli.",
                "Doğrusu bu gelişme pek çok kesimi yakından ilgilendiriyor.",
                "Gelen tepkilere bakılırsa bu tartışma daha epey sürecek gibi görünüyor.",
                "Burada asıl dikkat çeken nokta ise bundan sonra atılacak adımlar.",
                "Paylaşılan ek ayrıntılar konunun çerçevesini çok daha iyi ortaya koyuyor.",
                "Bu durum gündemdeki dengelerin nasıl şekillendiğini de gösteriyor."
            };
            var reaction = reactions[index % reactions.Length];

            var title = CleanForSpeech(story.TitleTr ?? story.TitleEn);
            var (_, secondPart) = SplitNarrative(story.NarrativeTr ?? story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(secondPart))
            {
                return $"{reaction} {secondPart}".Trim();
            }
            return $"{reaction} {BuildSourcesCommentaryTr(story, index)}".Trim();
        }

        private static string BuildStoryFollowUpEn(OverviewStory story, int index)
        {
            var reactions = new[]
            {
                "And when you look closer at the details, you can see why this is drawing so much reaction.",
                "Right, and the broader context in today's reporting really explains what is at stake.",
                "That context really matters, especially when you look at how the situation is unfolding.",
                "Indeed, and there's more to unpack when we look at the reactions coming in.",
                "And looking at the fallout from this, the implications go even further.",
                "What makes this particularly notable is where things could head next.",
                "The follow-up details here really help put the whole issue into perspective.",
                "It really highlights how closely this issue is being followed right now."
            };
            var reaction = reactions[index % reactions.Length];

            var title = CleanForSpeech(story.TitleEn ?? story.TitleTr);
            var (_, secondPart) = SplitNarrative(story.NarrativeEn, title);

            if (!string.IsNullOrWhiteSpace(secondPart))
            {
                return $"{reaction} {secondPart}".Trim();
            }
            return $"{reaction} {BuildSourcesCommentaryEn(story, index)}".Trim();
        }

        private static string BuildSourcesCommentaryEl(OverviewStory story, int index = 0)
        {
            var fallbacks = new[]
            {
                "Το θέμα παρακολουθείται στενά από τον Τύπο και αναμένονται νεότερα σύντομα.",
                "Οι επόμενες κινήσεις γύρω από αυτή την υπόθεση θα έχουν ιδιαίτερο ενδιαφέρον.",
                "Πρόκειται για μια εξέλιξη που απασχολεί έντονα τη δημόσια συζήτηση σήμερα.",
                "Θα δούμε πώς θα εξελιχθούν τα πράγματα τις αμέσως επόμενες μέρες."
            };
            return fallbacks[index % fallbacks.Length];
        }

        private static string BuildSourcesCommentaryTr(OverviewStory story, int index = 0)
        {
            var fallbacks = new[]
            {
                "Basında geniş yer bulan bu konuyla ilgili yeni gelişmeler bekleniyor.",
                "Bu başlıkta atılacak bir sonraki adımlar merakla takip ediliyor.",
                "Kamuoyunda geniş yankı bulan bu gelişmenin etkileri sürecek gibi görünüyor.",
                "Önümüzdeki günlerde sürecin nasıl şekilleneceğini birlikte göreceğiz."
            };
            return fallbacks[index % fallbacks.Length];
        }

        private static string BuildSourcesCommentaryEn(OverviewStory story, int index = 0)
        {
            var fallbacks = new[]
            {
                "It's a developing situation with plenty of attention on what happens next.",
                "The next steps here will be key to watch as more details emerge.",
                "It has sparked plenty of debate in today's coverage.",
                "We will see how this plays out over the next few days."
            };
            return fallbacks[index % fallbacks.Length];
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

        private static string ToConversationalClause(string rawTitle)
        {
            var cleaned = CleanForSpeech(rawTitle);
            if (string.IsNullOrWhiteSpace(cleaned))
            {
                return string.Empty;
            }
            cleaned = cleaned.Trim().TrimEnd('.', '!', '?', ';', ':');
            cleaned = Regex.Replace(cleaned, @"\s*:\s*", " — ");
            return cleaned;
        }

        private static readonly HashSet<string> PreserveCapitalizedWordsEn = new(StringComparer.OrdinalIgnoreCase)
        {
            "Cyprus", "Cypriot", "Cypriots", "Nicosia", "Lefkosa", "Lefkoşa", "Limassol", "Larnaca", "Paphos",
            "Famagusta", "Kyrenia", "Morphou", "Guzelyurt", "Güzelyurt", "Iskele", "İskele", "Karpas",
            "Greek", "Turkish", "Turkey", "Greece", "Athens", "Ankara", "London", "Brussels", "Geneva",
            "New", "York", "European", "Union", "United", "Nations", "Britain", "British", "Israel", "Lebanon",
            "Christodoulides", "Tatar", "Erhurman", "Erhürman", "Arikli", "Arıklı", "Ustel", "Üstel",
            "Ozgurguc", "Atun", "avrupa", "Politis", "Phileleftheros", "Kibris", "Kıbrıs", "Cronos", "Aphrodite",
            "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
        };

        private static string ToConversationalClauseEn(string rawTitle)
        {
            var cleaned = CleanForSpeech(rawTitle);
            if (string.IsNullOrWhiteSpace(cleaned))
            {
                return string.Empty;
            }
            cleaned = cleaned.Trim().TrimEnd('.', '!', '?', ';', ':');
            cleaned = Regex.Replace(cleaned, @"\s*:\s*", " and ");

            var words = cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < words.Length; i++)
            {
                var w = words[i];
                var stripped = Regex.Replace(w, @"[^\p{L}]", "");
                if (string.IsNullOrEmpty(stripped))
                {
                    continue;
                }
                // Keep all-caps acronyms (UBP, YDP, EU, UN, etc.) and known proper nouns capitalized
                if (stripped.Length >= 2 && stripped.All(char.IsUpper))
                {
                    continue;
                }
                if (PreserveCapitalizedWordsEn.Contains(stripped))
                {
                    continue;
                }
                words[i] = w.ToLowerInvariant();
            }

            return string.Join(" ", words);
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

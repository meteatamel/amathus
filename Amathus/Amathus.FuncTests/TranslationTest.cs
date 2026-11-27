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
using System.Collections.Generic;
using System.Threading.Tasks;
using Amathus.Common.FeedStore;
using Amathus.Common.Translation;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.FuncTests
{
    [TestClass]
    public class TranslationTest
    {
        [TestMethod]
        public void SanitizeHtmlForTranslation_StripsScriptsStylesAndCmsAttributes()
        {
            var dirty = @"
                <!-- comment -->
                <div class=""wp-block-group"" style=""color:red;"" data-track=""123"">
                    <script>alert('xss')</script>
                    <style>.foo { display:none; }</style>
                    <p class=""lead"" id=""p1"">Hello <a href=""https://example.com/news"" target=""_blank"" rel=""noopener"">Cyprus</a>!</p>
                    <img src=""https://example.com/img.jpg"" srcset=""a.jpg 2x"" width=""800"" loading=""lazy"" />
                    <iframe src=""https://ads.example.com""></iframe>
                </div>";

            var cleaned = GeminiTranslationService.SanitizeHtmlForTranslation(dirty);

            Assert.IsFalse(cleaned.Contains("script"));
            Assert.IsFalse(cleaned.Contains("alert"));
            Assert.IsFalse(cleaned.Contains("style="));
            Assert.IsFalse(cleaned.Contains("wp-block-group"));
            Assert.IsFalse(cleaned.Contains("data-track"));
            Assert.IsFalse(cleaned.Contains("srcset"));
            Assert.IsFalse(cleaned.Contains("iframe"));
            Assert.IsTrue(cleaned.Contains("<p>Hello <a href=\"https://example.com/news\">Cyprus</a>!</p>"));
            Assert.IsTrue(cleaned.Contains("<img src=\"https://example.com/img.jpg\">"));
        }

        [TestMethod]
        public async Task TranslateArticleAsync_CachesFieldsIndependentlyAcrossDetailExpansion()
        {
            GeminiTranslationService.ClearMemoryCacheForTests();
            var store = new InMemoryFeedStore();
            var calls = new List<(string title, string summary, string detail)>();

            GeminiTranslationService.TestBatchTranslator = (title, summary, detail, src, tgt) =>
            {
                calls.Add((title, summary, detail));
                return Task.FromResult(new GeminiBatchTranslationOutput
                {
                    DetectedSourceLanguage = src ?? "tr",
                    Title = title != null ? $"[EN]{title}" : null,
                    Summary = summary != null ? $"[EN]{summary}" : null,
                    Detail = detail != null ? $"[EN]{detail}" : null
                });
            };

            try
            {
                // 1. Feed list view translates Title + Summary (no Detail)
                var listResult = await GeminiTranslationService.TranslateArticleAsync(
                    title: "Lefkoşa'da yeni karar",
                    summary: "Kısa özet",
                    detail: "",
                    sourceLang: "tr",
                    targetLang: "en",
                    storeOverride: store);

                Assert.AreEqual("[EN]Lefkoşa'da yeni karar", listResult.Title);
                Assert.AreEqual("[EN]Kısa özet", listResult.Summary);
                Assert.AreEqual(string.Empty, listResult.Detail);
                Assert.AreEqual(1, calls.Count);
                Assert.AreEqual("Lefkoşa'da yeni karar", calls[0].title);
                Assert.AreEqual("Kısa özet", calls[0].summary);
                Assert.IsNull(calls[0].detail);

                // 2. User taps into the article (Detail now included) -> MUST reuse cached Title & Summary!
                var detailResult = await GeminiTranslationService.TranslateArticleAsync(
                    title: "Lefkoşa'da yeni karar",
                    summary: "Kısa özet",
                    detail: "<p class=\"body\">Detaylı haber metni</p>",
                    sourceLang: "tr",
                    targetLang: "en",
                    storeOverride: store);

                Assert.AreEqual("[EN]Lefkoşa'da yeni karar", detailResult.Title);
                Assert.AreEqual("[EN]Kısa özet", detailResult.Summary);
                Assert.AreEqual("[EN]<p>Detaylı haber metni</p>", detailResult.Detail);
                Assert.AreEqual(2, calls.Count);
                Assert.IsNull(calls[1].title);
                Assert.IsNull(calls[1].summary);
                Assert.AreEqual("<p>Detaylı haber metni</p>", calls[1].detail);

                // 3. Clearing L1 memory cache still hits L2 persistent store (0 new model calls!)
                GeminiTranslationService.ClearMemoryCacheForTests();
                var l2Hit = await GeminiTranslationService.TranslateArticleAsync(
                    title: "Lefkoşa'da yeni karar",
                    summary: "Kısa özet",
                    detail: "<p class=\"body\">Detaylı haber metni</p>",
                    sourceLang: "tr",
                    targetLang: "en",
                    storeOverride: store);

                Assert.AreEqual("[EN]Lefkoşa'da yeni karar", l2Hit.Title);
                Assert.AreEqual("[EN]<p>Detaylı haber metni</p>", l2Hit.Detail);
                Assert.AreEqual(2, calls.Count);
            }
            finally
            {
                GeminiTranslationService.TestBatchTranslator = null;
                GeminiTranslationService.ClearMemoryCacheForTests();
            }
        }

        [TestMethod]
        public async Task TranslateArticleAsync_SameSourceAndTarget_SkipsModelCall()
        {
            GeminiTranslationService.ClearMemoryCacheForTests();
            var called = false;
            GeminiTranslationService.TestBatchTranslator = (t, s, d, src, tgt) =>
            {
                called = true;
                return Task.FromResult(new GeminiBatchTranslationOutput());
            };

            try
            {
                var res = await GeminiTranslationService.TranslateArticleAsync(
                    title: "Already English",
                    summary: "Summary",
                    detail: "<p>Body</p>",
                    sourceLang: "en",
                    targetLang: "en");

                Assert.IsFalse(called);
                Assert.AreEqual("Already English", res.Title);
                Assert.AreEqual("en", res.SourceLanguage);
                Assert.AreEqual("en", res.TargetLanguage);
            }
            finally
            {
                GeminiTranslationService.TestBatchTranslator = null;
            }
        }
    }
}

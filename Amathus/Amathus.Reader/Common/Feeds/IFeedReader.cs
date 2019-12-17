using System.Collections.Generic;
using System.Threading.Tasks;

namespace Amathus.Reader.Common.Feeds
{
    public interface IFeedReader
    {
        Task<IEnumerable<Feed>> Read();

        Feed Read(FeedId sourceId);
    }
}

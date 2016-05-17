public class SharepointDTO 
{
    public SharepointResults d;
    
    public class SharepointResults 
    {
        public ResponseFromSP[] results;
    }
    
    public class ResponseFromSP 
    {
        public MetadataClass metadata;
        public FilesClass Files;
        public FoldersClass Folders;
        public String Name;
        public DateTime TimeLastModified;
        //public String ServerRelativeUrl;
        public Integer ItemCount;
        public String UniqueId;
    }
    public class MetadataClass 
    {
        public String id;   
        public String uri;
        public String type;
    }
    public class FilesClass
    {
        public DeferredClass deferred;
    }
    public class DeferredClass 
    {
        public String uri; 
    }
    
    public class FoldersClass
    {
        public DeferredClass deferred;
    }
}
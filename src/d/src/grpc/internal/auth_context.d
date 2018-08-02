module grpc.internal.auth_context;

abstract class AuthContext
{
public:

    /// Returns true if the peer is authenticated.
    bool isPeerAuthenticated();

    /// A peer identity.
    ///
    /// It is, in general, comprised of one or more properties (in which case they
    /// have the same name).
    @property
    string[] peerIdentity();

    @property
    string peerIdentityPropertyName();
    @property
    void peerIdentityPropertyName(string name);

    /// Returns all the property values with the given name.
    string[] findPropertyValues(string name);

    /// Iteration over all the properties.
    //virtual AuthPropertyIterator begin();
    //virtual AuthPropertyIterator end();

    /// Mutation functions: should only be used by an AuthMetadataProcessor.
    void addProperty(string key, string value);
}

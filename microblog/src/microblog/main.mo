import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {
    private type Message = {
    
        time : Time.Time;
        text : Text;
    };

    private type Microblog = actor{
        follow: shared (Principal) -> async ();
        follows: shared query() -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Time.Time) -> async [Message]; 
        timeline: shared (Time.Time) -> async [Message];
    };

    stable var followed : List.List<Principal> = List.nil();

    public shared ({caller}) func follow(id : Principal) : async () {
        followed := List.push(id, followed);
    };

    public shared query func follows() : async [Principal]{
        return List.toArray(followed);
    };

    stable var messages : List.List<Message> = List.nil();

    public shared ({caller}) func post(text : Text) : async () {
        var msg : Message = {
            text = text;
            time = Time.now();
        };
        messages := List.push(msg, messages);
    };

    public shared query func posts(since : Time.Time) : async [Message] {
        var since_message : List.List<Message> = List.nil();
        for (msg in Iter.fromList(messages)) {
            if (msg.time >= since) {
                since_message := List.push(msg, since_message);
            };
        };
        return List.toArray(since_message);
    };


    public shared func timeline(since : Time.Time) : async [Message] {
        var all : List.List<Message> = List.nil();

        for(id in Iter.fromList(followed)){
            let canister : Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for(msg in Iter.fromArray(msgs)){
                all := List.push(msg, all);
            };
        };

        return List.toArray(all);
    };
};

# YAYSON - Runtastic style

This codebase has introduced breaking changes which are fitted to our own use-cases,
it is highly opinionated of how the YAYSON `Store` class handles `links` and `meta`
attributes.

Also, we will most likely port the code later on, so we most likely stop maintaining this
repository as soon as this happens.

We may open-source the result of this port, but only if we find a solution which will work
with any JSONAPI endpoint without any pre-defined conditions (i.e. preventing meta attribute 
name collisions).

The reason why we don't contribute to the original YAYSON project is, that our use-cases / interest
most likely differs from the maintainer ones and we would like to iterate fast.

We try to contribute as much as possible, but right now I guess it's just not meant to be ;-)

Feel free to use, but use with cause.


## New interface for Store

```javascript

const store = new Store({
    addLinks: true,  //If true, will add nested links attribute to resolved models (default: false)
    addMeta: true,  //If true, will add nested meta atttribute to resolved models (default: false)
    throwWarning: false //If true, will throw on error if a meta / links attribute name collision happens
});


//.syncWithMeta wrap the result in a {data: {/*model data*/}, meta: {/*root level meta*/}} object
const synced = store.syncWithMeta({
    data: {
        id: "1"
        type: "event",
        meta: {
            "tickets_available": true
        },
        links: {
            "self": "event-self"
        },
        relationships: {
            images: {
                data: [
                    {id: "2", type: "image"}
                ],
                links: {
                    self: "images-self"
                },
                meta: {
                    "count": 10
                }
            }
        }
    },
    included: [{
        id: "2",
        type: "image",
        meta: {
            kbsize: 1000
        }
    }],
    "meta": {
        event_count: 20
    }
});

console.log(synced);
```

**Above example would output:**

```javascript
//This is just a wrapper object for root level meta / model data
{
    //Contains all resolved models
    "data": {
        "id": "1",
            "type": "event",

            //Here we got a nested meta with all relationship meta and own meta attributes 
            "meta": {
                "tickets_available": true,
                "images": {
                    "count": 10
                }
            },
            
            //Same for the links object
            "links": {
                "self": "event-self",
                "images": {
                    "self": "images-self"
                }
            },
            "images": [
                {
                    "id": "2",
                    "type": "image",

                    //Meta from the included data object
                    "meta": {
                        "kbsize": 1000
                    }
                }
            ]
    },

    //The root level meta object, still preserved which is nice
    "meta": {
        event_count: 20
    }
}
```


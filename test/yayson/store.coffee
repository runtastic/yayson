expect = require('chai').expect

Store = require('../../src/yayson.coffee')().Store

describe 'Store', ->
  beforeEach ->
    @store = new Store()

    @store.records = []
    @store.relations = {}

  it 'should sync an event', ->
    event = @store.sync data:
      type: 'events'
      id: 1
      attributes:
        name: 'Demo'

    expect(event.name).to.equal 'Demo'

  it 'should find an event', ->
    @store.sync data:
      type: 'events'
      id: 1
      attributes:
        name: 'Demo'

    event = @store.find 'events', 1
    expect(event.name).to.equal 'Demo'

  it 'should handle relations with duplicates', ->
    @store.sync
      data:
        type: 'events'
        id: 1
        attributes:
          name: 'Demo'
        relationships:
          images:
            data: [{
              type: 'images'
              id: 2
            }]
      included: [{
        type: 'images'
        id: 2
        attributes:
          name: 'Header'
      }, {
        type: 'images'
        id: 2
        attributes:
          name: 'Header'
      }]

    event = @store.find 'events', 1
    expect(event.name).to.equal 'Demo'
    expect(event.images.length).to.equal 1

    images = @store.findAll 'images'
    expect(images.length).to.eq 1

  it 'should handle relationship elements without links attribute', ->
      @store.sync
        data:
            type: 'events'
            id: 1
            attributes:
                name: 'Demo'
            relationships:
                image:
                    data: {
                        type: 'images',
                        id: 2
                    }
       event = @store.find 'events', 1

       expect(event.name).to.equal 'Demo'
       expect(event.image).to.be.null

  it 'should handle circular relations', ->
    @store.sync
      data:
        type: 'events'
        id: 1
        attributes:
          name: 'Demo'
        relationships:
          images:
            data: [
              type: 'images'
              id: 2
            ]
      included: [
          type: 'images'
          id: 2
          attributes:
            name: 'Header'
          relationships:
            event:
              data:
                type: 'events'
                id: 1
      ]

    event = @store.find 'events', 1
    expect(event.name).to.equal 'Demo'
    expect(event.images[0].name).to.equal 'Header'
    expect(event.images[0].event.id).to.equal 1

  it 'should handle relations with links', ->
    @store = new Store({ addLinks: true})

    @store.sync
      data:
        type: 'events'
        id: 1
        attributes:
          name: 'Demo'
        relationships:
          image:
            data: {
              type: 'images'
              id: 2
            }
            links:
              next: 'url-to-next',
              prev: 'url-to-prev'
      included: [{
        type: 'images'
        id: 2
        attributes:
          name: 'Header'
          links: 'Links attribute'
      }]

    event = @store.find 'events', 1
    expect(event.image.name).to.equal 'Header'
    expect(event.links).to.deep.equal({
      image: {
        next: 'url-to-next',
        prev: 'url-to-prev'
      }
    })

  it 'should return a event with all associated objects', ->
    @store.sync
      data:
        type: 'events'
        id: 1
        attributes:
          name: "Nordic.js"
          slug: "nordicjs"
        relationships:
          images:
            data: [
              {type: 'images', id: 1}
              {type: 'images', id: 2}
              {type: 'images', id: 3}
            ]
          organisers:
            data: [
              {type: 'organisers', id: 1}
              {type: 'organisers', id: 2}
            ]
      included: [{
        type: 'organisers'
        id: 1
        attributes:
          firstName: 'Jonny'
        relationships:
          event:
            data: {type: 'events', id: 1}
          image:
            data: {type: 'images', id: 2}
      },{
        type: 'organisers'
        id: 2
        attributes:
          firstName: 'Martina'
        relationships:
          event:
            data: {type: 'events', id: 1}
          image:
            data: {type: 'images', id: 3}
      },{
        type: 'images'
        id: 1
        attributes:
          name: 'Header'
        relationships:
          event:
            data: {type: 'events', id: 1}
      },{
        type: 'images'
        id: 2
        attributes:
          name: 'Organiser Johannes'
        relationships:
          event:
            data: {type: 'events', id: 1}
      },{
        type: 'images'
        id: 3
        attributes:
          name: 'Organiser Martina'
        relationships:
          event:
            data: {type: 'events', id: 1}
      }]

    event = @store.find 'events', 1
    expect(event.organisers.length).to.equal 2
    expect(event.images.length).to.equal 3
    expect(event.organisers[0].image.id).to.equal 2



  it 'should remove an event', ->
    @store.sync data: [
      {id: 1, type: 'events'}
      {id: 2, type: 'events'}
    ]

    event = @store.find 'events', 1
    expect(event.id).to.eq 1
    @store.remove 'events', 1
    event = @store.find 'events', 1
    expect(event).to.eq null


  it 'should remove all events', ->
    @store.sync data: [
      {id: 1, type: 'events'}
      {id: 2, type: 'events'}
    ]

    events = @store.findAll 'events'
    expect(events.length).to.eq 2
    @store.remove 'events'
    events = @store.findAll 'events'
    expect(events).to.deep.eq []


  it 'should reset', ->
    @store.sync
      data: [{
        type: 'events'
        id: 1
        attributes:
          name: 'Demo'
        relationships:
          images:
            data: [ type: 'images', id: 2 ]
      },{
        type: 'events'
        id: 2
        attributes:
          name: 'Demo 2'
      }]
      included: [
          type: 'images'
          id: 2
          attributes:
            name: 'Header'
          relationships:
            event:
              data: {type: 'events', id: 1}
      ]

    events = @store.findAll 'events'
    images = @store.findAll 'images'
    expect(events.length).to.eq 2
    expect(images.length).to.eq 1

    @store.reset()

    events = @store.findAll 'event'
    images = @store.findAll 'image'
    expect(events).to.deep.eq []
    expect(images).to.deep.eq []


  it 'should handle relationships with empty data attribute by setting attr to null', ->
    @store = new Store({ addLinks: true})

    @store.sync
      data:
        type: 'events'
        id: 1
        attributes:
          name: 'Demo'
        relationships:
          images:
            links:
              self: 'http://example.com/events/1/relationships/images'

    event = @store.find 'events', 1
    expect(event.name).to.equal 'Demo'

    expect(event.links).to.deep.equal({
      images: { self: 'http://example.com/events/1/relationships/images' }
    })

  it 'should include meta attributes in denormalized objects', ->
    @store = new Store({ addGet: false, addMeta: true })

    @store.sync
      data: [{
        type: 'events'
        id: 1
        attributes:
          name: 'Demo'
        relationships:
          images:
            links:
              self: 'http://example.com/events/1/relationships/images'
            meta:
              count: 20
          bookings:
            meta:
              max_attendees: 20
        meta:
          awesome: 'yes'
      }]

     event = @store.find 'events', 1

     expect(event.meta).to.deep.equal({
       awesome: 'yes',
       images:
         count: 20
       bookings:
         max_attendees: 20
     })

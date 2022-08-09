// To parse this JSON data, do
//
//     final ngRokEndpoint = ngRokEndpointFromJson(jsonString);

import 'dart:convert';

NgRokEndpoint ngRokEndpointFromJson(String str) => NgRokEndpoint.fromJson(json.decode(str));

class NgRokEndpoint {
    NgRokEndpoint({
        this.endpoints,
        this.uri,
    });

    List<Endpoint>? endpoints;
    String? uri;

    factory NgRokEndpoint.fromJson(Map<String, dynamic> json) => NgRokEndpoint(
        endpoints: json["endpoints"] == null ? null : List<Endpoint>.from(json["endpoints"].map((x) => Endpoint.fromJson(x))),
        uri: json["uri"],
    );
}

class Endpoint {
    Endpoint({
        this.id,
        this.region,
        this.createdAt,
        this.updatedAt,
        this.publicUrl,
        this.proto,
        this.hostport,
        this.type,
        this.metadata,
        this.tunnel,
    });

    String? id;
    String? region;
    DateTime? createdAt;
    DateTime? updatedAt;
    String? publicUrl;
    String? proto;
    String? hostport;
    String? type;
    String? metadata;
    Tunnel? tunnel;

    factory Endpoint.fromJson(Map<String, dynamic> json) => Endpoint(
        id: json["id"],
        region: json["region"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        publicUrl: json["public_url"],
        proto: json["proto"],
        hostport: json["hostport"],
        type: json["type"],
        metadata: json["metadata"],
        tunnel: json["tunnel"] == null ? null : Tunnel.fromJson(json["tunnel"]),
    );
}

class Tunnel {
    Tunnel({
        this.id,
        this.uri,
    });

    String? id;
    String? uri;

    factory Tunnel.fromJson(Map<String, dynamic> json) => Tunnel(
        id: json["id"],
        uri: json["uri"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "uri": uri,
    };
}

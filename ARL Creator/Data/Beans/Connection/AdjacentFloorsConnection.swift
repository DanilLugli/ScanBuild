//
//  AdjacentFloorsConnection.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation

class AdjacentFloorsConnection: Connection {
    private var _fromTransitionZone: String
    private var _targetFloor: String
    private var _targetRoom: String
    private var _targetTransitionZone: String
    
    init(name: String, fromTransitionZone: String, targetFloor: String, targetRoom: String, targetTransitionZone: String) {
        self._fromTransitionZone = fromTransitionZone
        self._targetFloor = targetFloor
        self._targetRoom = targetRoom
        self._targetTransitionZone = targetTransitionZone
        super.init(name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _fromTransitionZone = try container.decode(String.self, forKey: .fromTransitionZone)
        _targetFloor = try container.decode(String.self, forKey: .targetFloor)
        _targetRoom = try container.decode(String.self, forKey: .targetRoom)
        _targetTransitionZone = try container.decode(String.self, forKey: .targetTransitionZone)
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    var fromTransitionZone: String{
        get {
            return _fromTransitionZone
        }
        set {
            _fromTransitionZone = newValue
        }
    }
    
    var targetFloor: String {
        get {
            return _targetFloor
        }
        set {
            _targetFloor = newValue
        }
    }
    
    var targetRoom: String {
        get {
            return _targetRoom
        }
        set {
            _targetRoom = newValue
        }
    }
    
    var targetTransitionZone: String {
        get {
            return _targetTransitionZone
        }
        set {
            _targetTransitionZone = newValue
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case fromTransitionZone
        case targetFloor
        case targetRoom
        case targetTransitionZone
    }
}


//
//  ProjectKind.swift
//  
//
//  Created by Colton Schlosser on 6/19/20.
//

public enum ProjectKind {
    case project(path: String)
    case workspace(path: String, project: String)
}

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxBuilder
import Utils

let copyrightHeader = """
    //// Automatically Generated by generate-swiftsyntaxbuilder
    //// Do Not Edit Directly!
    //===----------------------------------------------------------------------===//
    //
    // This source file is part of the Swift.org open source project
    //
    // Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
    // Licensed under Apache License v2.0 with Runtime Library Exception
    //
    // See https://swift.org/LICENSE.txt for license information
    // See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
    //
    //===----------------------------------------------------------------------===//


    """

func createSpacingCall() -> MemberAccessExpr {
  MemberAccessExpr(name: "space")
}

func createWithLeadingTriviaCall() -> FunctionCallExpr {
  FunctionCallExpr(MemberAccessExpr(name: "withLeadingTrivia")) {
    TupleExprElement(expression: createSpacingCall())
  }
}

func createWithTrailingTriviaCall() -> FunctionCallExpr {
  FunctionCallExpr(MemberAccessExpr(name: "withTrailingTrivia")) {
    TupleExprElement(expression: createSpacingCall())
  }
}

func createTokenPatternBinding(_ pattern: ExpressibleAsPatternBuildable, accessor: ExpressibleAsSyntaxBuildable) -> PatternBinding {
  PatternBinding(pattern: pattern,
                 typeAnnotation: "Token",
                 initializer: nil,
                 accessor: accessor)
}

func createTypeInheritanceClause(conformances: [String]) -> TypeInheritanceClause? {
  conformances.isEmpty ? nil : TypeInheritanceClause {
    for conformance in conformances {
      InheritedType(typeName: conformance)
    }
  }
}

/// Create a parameter clause of the form `format: Format`.
func createFormatParameters() -> ParameterClause {
  ParameterClause {
    FunctionParameter(
      firstName: .identifier("format"),
      colon: .colon,
      type: "Format"
    )
  }
}

/// Generate the `create...` function for an `ExpressibleAs...` conformance.
func createExpressibleAsCreateFunction(type: SyntaxBuildableType, additionalDocComments: [String] = []) -> FunctionDecl {
  FunctionDecl(
    leadingTrivia: ([
      "/// Conformance to `\(type.expressibleAsBaseName)`.",
    ] + additionalDocComments).map { .docLineComment($0) + .newline }.reduce([], +),
    modifiers: [Token.public],
    identifier: .identifier("create\(type.buildableBaseName)"),
    signature: FunctionSignature(
      input: ParameterClause(),
      output: type.buildable
    )
  ) {
    ReturnStmt(expression: "self")
  }
}

/// Generate the `create...` function for an `ExpressibleAs...` conformance
/// that includes an explanation as to how the function disambiguates a conformance.
func createDisambiguatingExpressibleAsCreateFunction(type: SyntaxBuildableType, baseType: SyntaxBuildableType) -> FunctionDecl {
  createExpressibleAsCreateFunction(type: baseType, additionalDocComments: [
    "/// `\(type.buildableBaseName)` may conform to `\(baseType.expressibleAsBaseName)` via different `ExpressibleAs*` paths.",
    "/// Thus, there are multiple default implementations of `create\(baseType.buildableBaseName)`, some of which perform conversions",
    "/// through `ExpressibleAs*` protocols. To resolve the ambiguity, provie a fixed implementation that doesn't perform any conversions.",
  ]) 
}

/// Generate a `withATrivia` function.
func createWithTriviaFunction(trivia: String) -> FunctionDecl {
  FunctionDecl(
    modifiers: [Token.public],
    identifier: .identifier("with\(trivia.withFirstCharacterUppercased)"),
    signature: FunctionSignature(
      input: ParameterClause {
        FunctionParameter(
          firstName: .wildcard,
          secondName: .identifier(trivia),
          colon: .colon,
          type: "Trivia"
        )
      },
      output: "Self"
    )
  ) {
    VariableDecl(.var, name: "result", initializer: "self")
    SequenceExpr {
      MemberAccessExpr(base: "result", name: trivia)
      AssignmentExpr()
      trivia
    }
    ReturnStmt(expression: "result")
  }
}

func createTriviaAttachment(varName: String, triviaVarName: String, trivia: String) -> IfStmt {
  IfStmt(
    conditions: ExprList {
      PrefixOperatorExpr(
        operatorToken: .prefixOperator("!"),
        postfixExpression: MemberAccessExpr(base: triviaVarName, name: "isEmpty")
      )
    }
  ) {
    SequenceExpr {
      varName
      AssignmentExpr()
      FunctionCallExpr(MemberAccessExpr(base: varName, name: "with\(trivia.withFirstCharacterUppercased)")) {
        TupleExprElement(expression: SequenceExpr {
          triviaVarName
          BinaryOperatorExpr("+")
          TupleExpr {
            SequenceExpr {
              MemberAccessExpr(base: varName, name: trivia)
              BinaryOperatorExpr("??")
              ArrayExpr()
            }
          }
        })
      }
    }
  }
}

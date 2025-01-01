/* global cy */
/// <reference types="cypress" />

context('Function Documentation', () => {
  beforeEach(() => {
    cy.visit('')
    // TODO: Generate index in beforeAll
  })
  describe('landing page', () => {
    it('should show heading', () => {
      cy.get('h1')
        .contains('Function Documentation')
    })
  })

  describe('simple search', () => {
    it('should find article with extended markdown contents', () => {
      cy.get('#query-field')
        .type('file:sync')
      cy.get('.function-head > h4')
        .should('exist')
        .click()
      cy.get('.extended-docs')
        .should('exist')
        .click()
      cy.get('zero-md')
        .should('exist')
    })
  })  
})

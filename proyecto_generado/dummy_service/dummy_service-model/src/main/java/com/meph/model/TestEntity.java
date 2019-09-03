package com.meph.model;

import lombok.Data;
import lombok.EqualsAndHashCode;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * Direccion de correo que se ha de wrappear con una cuenta de test.
 *
 * @author 03556158
 *
 */
@Table(name = "TEST")
@Entity
@Data
public class TestEntity {
    @Id
    @Column(name = "id")
    private String id;
}
